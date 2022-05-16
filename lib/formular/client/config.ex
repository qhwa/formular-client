defmodule Formular.Client.Config do
  @moduledoc """
  Configuration for a Formular client.

  The following keys are currently supported:

  - `client_name`
    - the identity of the client, can be any string. Default `nil`
  - `url`
    - the url of the remote server, default `nil`
  - `read_timeout`
    - a timeout setting for waiting for all the formulas
  - `formulas`
    - formula definition, check "Formula Configuration" section for more
      information.
  - `compiler`
    - MFA config for compiling the string into Elixir code
  - `adapter`
    - an adapter for getting the data from the remote server

  ## Formula Configuration

  A fomular is configured as a three-element tuple:

  ```elixir
  {MyFm, "my-formula", My.ContextModule}
  ```

  Here `MyFm` is the name of module for the code to be compiled into;
  `"my-formula"` is the name of the formula on the server;
  `My.ContextModule` is the helper module that can be used in the 
  code.
  ```
  """
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
          read_timeout: :infinity | non_neg_integer(),
          formulas: [formula_def()],
          compiler: {module(), atom(), args :: list()} | compile_function(),
          adapter: {module(), keyword()}
        }

  defstruct [
    :client_name,
    :url,
    formulas: [],
    read_timeout: :infinity,
    compiler: {Formular.Client.Compiler, :compile, []},
    adapter: {Formular.Client.Adapter.Websocket, []}
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
      &Enum.map(&1 || [], fn
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
end
