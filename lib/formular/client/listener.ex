defmodule Formular.Client.Listener do
  alias Formular.Client.Websocket
  alias Formular.Client.Config

  use GenServer
  require Logger

  def start_link(%Config{} = config) do
    GenServer.start_link(__MODULE__, config)
  end

  def start_link(config) do
    GenServer.start_link(__MODULE__, Config.new(config))
  end

  @impl true
  def init(config) do
    {:ok, config, {:continue, :start_socket}}
  end

  @impl true
  def handle_continue(:start_socket, config) do
    start_socket(config)
    {:noreply, config}
  end

  defp start_socket(config) do
    DynamicSupervisor.start_child(
      Formular.Client.Sockets,
      %{
        id: :erlang.unique_integer([:monotonic]),
        start: {Websocket, :start_link, [config]},
        restart: :permanent
      }
    )
  end
end
