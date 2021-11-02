defmodule Formular.Client.Compiler do
  require Logger
  alias Formular.Client.Config

  def handle_new_code_revision(name, code, config) do
    with {mod, name, context} <- Config.formula_config(config, name) do
      case config do
        %{compiler: {m, f}} ->
          apply(m, f, [{code, name, mod, context}])

        %{compiler: {m, f, a}} ->
          apply(m, f, [{code, name, mod, context} | a])

        %{compiler: f} when is_function(f, 1) ->
          apply(f, [{code, name, mod, context}])

        _ ->
          {:error, :nocompiler}
      end
    end
  end

  def compile({code, name, mod, context}) do
    Logger.info(["Recompiling formula: #{name} to module #{mod}. Code: #{code}"])

    prev_mc_config = Code.get_compiler_option(:ignore_module_conflict)
    Code.put_compiler_option(:ignore_module_conflict, true)
    Formular.compile_to_module!(code, mod, context)
    Code.put_compiler_option(:ignore_module_conflict, prev_mc_config)
    :ok
  end
end
