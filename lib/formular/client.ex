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

      {:code, code} ->
        Formular.eval(code, binding, options)

      {:module, mod} ->
        Formular.eval({:module, mod}, binding, options)
    end
  end

  defp code_or_module!(name) do
    case Cache.get(name) do
      {nil, code} when is_binary(code) ->
        {:code, code}

      code when is_binary(code) ->
        {:code, code}

      nil ->
        raise "Code has not been fetched"

      mod when is_atom(mod) ->
        {:module, mod}

      {mod, _code} when is_atom(mod) and not is_nil(mod) ->
        {:module, mod}

      f when is_function(f, 2) ->
        {:function, f}
    end
  end
end
