defmodule Formular.Client.Compiler do
  @moduledoc """
  Compiler for making the string code into an Elixir module.

  Here we use Agent to prevent concurrent compilation.
  """

  alias Formular.Client.PubSub

  use GenServer
  require Logger

  @reg Formular.Client.Compiler.Registry
  @compile_timeout :timer.minutes(1)
  @idle_timeout :timer.minutes(1)

  def handle_new_code_revision({pid, ref}, name, code, config, opts) do
    {:ok, server} = try_start(name)

    timeout = Map.get(config, :read_timeout, @compile_timeout)
    GenServer.call(server, {:compile, {pid, ref, code, config, opts}}, timeout)

    :ok
  end

  defp try_start(name) do
    case GenServer.start_link(__MODULE__, name, name: via_tuple(name)) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp via_tuple(name),
    do: {:via, Registry, {@reg, name}}

  @impl true
  def init(name) do
    {:ok, name}
  end

  @impl true
  def handle_call({:compile, {pid, ref, code, config, opts}}, _from, name) do
    case config do
      %{compiler: {m, f, a}} ->
        apply(m, f, [{code, name, opts} | a])
        |> report_result({pid, ref}, {name, opts}, code)

      %{compiler: f} when is_function(f, 1) ->
        apply(f, [{code, name, opts}])
        |> report_result({pid, ref}, {name, opts}, code)
    end

    {:reply, :ok, name, @idle_timeout}
  end

  @impl true
  def handle_info(:timeout, name) do
    {:stop, :normal, name}
  end

  def compile({code, name, opts}) do
    mod = Keyword.get(opts, :compile_as)

    Logger.info(["Recompiling formula: #{name} to module #{mod}. Code: #{inspect(code)}"])

    case mod do
      nil ->
        :ok

      _ when is_atom(mod) ->
        temporarily_disable_compilation_warning(fn ->
          do_compile(code, name, opts)
        end)
    end
  end

  defp do_compile(code, _name, opts) do
    mod = Keyword.get(opts, :compile_as)

    with {:module, ^mod} <- Formular.compile_to_module!(code, mod, opts) do
      :ok
    end
  rescue
    e in CompileError ->
      {:error, e}
  end

  defp temporarily_disable_compilation_warning(f) do
    prev_mc_config = Code.get_compiler_option(:ignore_module_conflict)
    Code.put_compiler_option(:ignore_module_conflict, true)

    ret = f.()

    Code.put_compiler_option(:ignore_module_conflict, prev_mc_config)

    ret
  end

  defp report_result(:ok, {pid, ref}, {name, opts}, code) do
    broadcast_success(name, code, opts[:compile_as], opts[:context])
    send(pid, {ref, :ok})
  end

  defp report_result({:error, e}, {pid, ref}, {name, opts}, code) do
    broadcast_failure(e, name, code, opts[:compile_as], opts[:context])
    send(pid, {ref, {:error, e}})
  end

  defp broadcast_success(name, code, mod, context) do
    PubSub.dispatch({:compiled, name, code, mod: mod, context: context})
  end

  defp broadcast_failure(err, name, code, mod, context) do
    PubSub.dispatch({:compile_failed, name, err, code, mod: mod, context: context})
  end
end
