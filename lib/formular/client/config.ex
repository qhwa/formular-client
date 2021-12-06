defmodule Formular.Client.Config do
  alias __MODULE__

  @type formula_name() :: String.t()
  @type formula_def :: {module(), formula_name(), context :: module()}
  @type formula_full_def :: formula_def() | {module(), name :: String.t()}

  @type compile_function ::
          ({name :: String.t(), code :: binary(), module(), nil | module()} ->
             :ok | {:error, term()})

  @type t :: %Config{
          client_name: String.t(),
          url: String.t(),
          formulas: [formula_def()],
          compiler: {module(), atom(), args :: list()} | compile_function()
        }

  defstruct [
    :client_name,
    :url,
    :formulas,
    compiler: {Formular.Client.Compiler, :compile, []}
  ]

  @doc """
  Build a new config constructure.
  """
  @spec new(Enum.t()) :: t()
  def new(opts) do
    struct!(Config, opts)
    |> format_formulas()
  end

  defp format_formulas(config) do
    config
    |> Map.update!(
      :formulas,
      &Enum.map(&1, fn
        name when is_binary(name) ->
          {nil, name, nil}

        {_, _, _} = f ->
          f

        {mod, name} ->
          {mod, name, nil}
      end)
    )
  end

  @doc """
  Get the config for a given formula name.
  """
  @spec formula_config(t(), formula_name()) :: formula_def() | nil
  def formula_config(%Config{formulas: formulas}, name) when is_list(formulas) do
    Enum.find(formulas, fn
      {_mod, ^name, _context} ->
        true

      _ ->
        false
    end)
  end

  def formula_config(_, _name) do
    nil
  end
end
