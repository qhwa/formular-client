defmodule Formular.Client.Compiler do
  @moduledoc """
  Compiler for making the string code into an Elixir module.

  Here we use Agent to prevent concurrent compilation.
  """

  alias Formular.Client.PubSub

  use Agent
  require Logger

  def start_link(opts),
    do: Agent.start_link(fn -> nil end, Keyword.put_new(opts, :name, __MODULE__))

  def handle_new_code_revision({pid, ref}, name, code, config, opts) do
    Agent.update(__MODULE__, fn _ ->
      case config do
        %{compiler: {m, f, a}} ->
          apply(m, f, [{code, name, opts} | a])
          |> report_result({pid, ref}, {name, opts}, code)

        %{compiler: f} when is_function(f, 1) ->
          apply(f, [{code, name, opts}])
          |> report_result({pid, ref}, {name, opts}, code)
      end

      nil
    end)
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
