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

  def eval(name, binding, options \\ []) do
    case code_or_module!(name) do
      {:function, f} ->
        {:ok, f.(binding, options)}

      other ->
        other |> Formular.eval(binding, options)
    end
  end

  defp code_or_module!(name) do
    case Cache.get(name) do
      code when is_binary(code) ->
        code

      nil ->
        raise "Code has not been fetched"

      mod when is_atom(mod) ->
        {:module, mod}

      f when is_function(f, 2) ->
        {:function, f}
    end
  end
end
