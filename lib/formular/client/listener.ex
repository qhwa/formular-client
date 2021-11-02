defmodule Formular.Client.Listener do
  alias __MODULE__
  alias Formular.Client.Websocket

  use GenServer
  require Logger

  defstruct [:config]

  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  @impl true
  def init(config) do
    {:ok, %Listener{config: config}, {:continue, :start_socket}}
  end

  @impl true
  def handle_continue(:start_socket, %{config: config} = listener) do
    url = Keyword.fetch!(config, :url)
    formulas = Keyword.fetch!(config, :formulas)

    for {name, mod, context} <- formulas,
        do:
          start_socket(url,
            name: name,
            handle_data: &compile({&1, name, mod, context})
          )

    {:noreply, listener}
  end

  defp start_socket(url, opts) do
    DynamicSupervisor.start_child(
      Formular.Client.Sockets,
      %{
        id: opts[:name],
        start: {Websocket, :start_link, [url, opts]},
        restart: :permanent
      }
    )
  end

  defp compile({code, name, mod, context}) do
    Logger.info(["Recompiling formula: #{name} to module #{mod}."])

    prev_mc_config = Code.get_compiler_option(:ignore_module_conflict)
    Code.put_compiler_option(:ignore_module_conflict, true)
    Formular.compile_to_module!(code, mod, context)
    Code.put_compiler_option(:ignore_module_conflict, prev_mc_config)
  end
end
