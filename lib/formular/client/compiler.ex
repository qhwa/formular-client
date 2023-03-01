defmodule Formular.Client.Compiler do
  @moduledoc """
  Compiler for making the string code into an Elixir module.

  Here we use Agent to prevent concurrent compilation.
  """

  alias Formular.Client.Config
  alias Formular.Client.PubSub

  use Agent
  require Logger

  def start_link(opts),
    do: Agent.start_link(fn -> nil end, Keyword.put_new(opts, :name, __MODULE__))

  def handle_new_code_revision({pid, ref}, name, code, config) do
    Agent.update(__MODULE__, fn _ ->
      with {mod, name, context} = formula_cfg <- Config.formula_config(config, name) do
        case config do
          %{compiler: {m, f, a}} ->
            apply(m, f, [{code, name, mod, context} | a])
            |> report_result({pid, ref}, formula_cfg, code)

          %{compiler: f} when is_function(f, 1) ->
            apply(f, [{code, name, mod, context}])
            |> report_result({pid, ref}, formula_cfg, code)
        end
      end

      nil
    end)
  end

  def compile({code, name, mod, context}) do
    Logger.info(["Recompiling formula: #{name} to module #{mod}. Code: #{inspect(code)}"])

    temporarily_disable_compilation_warning(fn ->
      do_compile(code, name, mod, context)
    end)
  end

  defp do_compile(code, _name, mod, context) do
    Formular.compile_to_module!(code, mod, context)
    :ok
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

  defp report_result(:ok, {pid, ref}, {mod, name, context}, code) do
    broadcast_success(name, code, mod, context)
    send(pid, {ref, :ok})
  end

  defp report_result({:error, e}, {pid, ref}, {mod, name, context}, code) do
    broadcast_failure(e, name, code, mod, context)
    send(pid, {ref, {:error, e}})
  end

  defp broadcast_success(name, code, mod, context) do
    PubSub.dispatch({:compiled, name, code, mod: mod, context: context})
  end

  defp broadcast_failure(err, name, code, mod, context) do
    PubSub.dispatch({:compile_failed, name, err, code, mod: mod, context: context})
  end
end
