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

  A fomular is configured as a two-element tuple:

  ```elixir
  {"my-formula", compile_as: MyFm, context: My.ContextModule}
  ```

  Here `MyFm` is the name of module for the code to be compiled into;
  `"my-formula"` is the name of the formula on the server;
  `My.ContextModule` is the helper module that can be used in the 
  code.
  ```

  A single formula name string is also accepted:

  ```elixir
  [
    ...
    formulas: ["my-formula"]
  ]
  ```

  In this case, `compile_as` and `context` are optional and treated as
  `nil`s.
  """
  alias __MODULE__

  require Logger

  @type formula_name() :: String.t()
  @type formula_def() :: {formula_name(), compile_options()}
  @type compile_options() :: [compile_option()]
  @type compile_option() ::
          {:compile_as, module()} | {:context, module()} | {:allow_modules, [module()]}
  @type formula_full_def() ::
          formula_def()
          | {module(), name :: String.t(), module() | nil}
          | {module(), name :: String.t()}

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
    read_timeout: 10_000,
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
          {name, []}

        {mod, name} when is_atom(mod) and is_binary(name) ->
          Logger.warning(
            "This format ({module, formula_name}) of formula Configuration is deprecated, please use `{formula_name, compile_as: module}` format."
          )

          {name, compile_as: mod}

        {name, opts} when is_binary(name) and is_list(opts) ->
          {name, opts}

        {mod, name, context} when is_atom(mod) and is_binary(name) and is_atom(context) ->
          Logger.warning(
            "This format ({module, formula_name, context}) of formula Configuration is deprecated, please use `{formula_name, compile_as: module, context: context}` format."
          )

          {name, compile_as: mod, context: context}
      end)
    )
  end

  @doc """
  Get the config for a given formula name.
  """
  @spec formula_config(t(), formula_name()) :: formula_def() | nil
  def formula_config(%Config{formulas: formulas}, name) when is_list(formulas) do
    Enum.find(formulas, fn
      {^name, _opts} ->
        true

      _ ->
        false
    end)
  end
end
