defmodule Formular.Client do
  @moduledoc """
  Documentation for `Formular.Client`.
  """

  alias Formular.Client.Cache

  @spec eval(
          name :: binary(),
          binding :: keyword(),
          options :: Formular.options()
        ) :: {:ok, term()} | {:error, term()}

  def eval(name, binding, options \\ []),
    do: code_or_module!(name) |> Formular.eval(binding, options)

  defp code_or_module!(name) do
    case Cache.get(name) do
      code when is_binary(code) ->
        code

      nil ->
        raise "Code has not been fetched"

      mod when is_atom(mod) ->
        {:module, mod}
    end
  end
end
