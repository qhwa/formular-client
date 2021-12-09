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
    {:ok, _child} = start_socket(config)
    wait_for_formulas(config)
    {:ok, config}
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

  defp wait_for_formulas(%{formulas: formulas} = config) do
    all_loaded =
      Enum.all?(formulas, fn {_, name, _} ->
        Formular.Client.Cache.get(name)
      end)

    if all_loaded do
      :ok
    else
      :timer.sleep(200)
      wait_for_formulas(config)
    end
  end
end
