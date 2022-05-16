# Copied from: https://github.com/J0/phoenix_gen_socket_client/blob/master/test/support/test_site.ex
defmodule TestSite do
  @moduledoc false

  defmodule Endpoint do
    @moduledoc false
    use Phoenix.Endpoint, otp_app: :formular_client

    socket("/socket", TestSite.Socket,
      websocket: true,
      longpoll: false
    )

    @impl true
    def init(_, config) do
      {:ok, config}
    end
  end

  defmodule Socket do
    @moduledoc false
    use Phoenix.Socket

    channel("formula:*", TestSite.Channel)

    def connect(_params, socket) do
      {:ok, socket}
    end

    def id(_socket), do: ""
  end

  defmodule Channel do
    @moduledoc false

    use Phoenix.Channel
    require Logger

    @impl true
    def join("formula:" <> name, payload, socket) do
      Logger.info(["New client joined channel: formula:#{name}, ", inspect(payload)])

      formula = %{
        code: inspect(name)
      }

      send(self(), :after_join)
      Phoenix.PubSub.subscribe(TestSite.PubSub, "formula:#{name}")

      {:ok, assign(socket, :formula, formula)}
    end

    @impl true
    def handle_info(:after_join, socket) do
      push(socket, "data", socket.assigns.formula)

      {:noreply, socket}
    end

    def handle_info({:update, formula}, socket) do
      push(socket, "data", formula)

      {:noreply, assign(socket, :formula, formula)}
    end
  end
end
