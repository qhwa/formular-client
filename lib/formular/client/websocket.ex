defmodule Formular.Client.Websocket do
  use WebSockex
  require Logger

  def start_link(url, opts) do
    Logger.debug(["Starting new formula websocket client, ", url, ", ", opts[:name]])

    url = url <> "?vsn=2.0.0"
    WebSockex.start_link(url, __MODULE__, opts)
  end

  @impl true
  def handle_connect(_conn, opts) do
    Logger.debug(["Socket connected. ", opts[:name]])

    client = self()
    topic = "formula:#{opts[:name]}"

    spawn_link(fn ->
      :timer.sleep(1)

      WebSockex.send_frame(
        client,
        {:text, ~s|["1", "1", "#{topic}", "phx_join", {}]|}
      )
    end)

    {:ok, opts}
  end

  @impl true
  def handle_frame({:text, msg}, opts) do
    msg
    |> Jason.decode!()
    |> handle_data(opts)

    {:ok, opts}
  end

  def handle_frame(data, state) do
    Logger.warn(["unprocessed data: ", inspect(data)])

    {:ok, state}
  end

  defp handle_data([_, _, _, "data", %{"code" => code}], opts) do
    Logger.info(["Got data for formula #{opts[:name]}."])

    opts[:handle_data].(code)
  end

  defp handle_data(_data, _opts) do
    :ok
  end
end
