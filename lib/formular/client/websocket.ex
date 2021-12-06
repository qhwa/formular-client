defmodule Formular.Client.Websocket do
  alias Phoenix.Channels.GenSocketClient
  alias Formular.Client.Config

  @behaviour GenSocketClient
  @reconnect_delay :timer.seconds(5)

  require Logger

  def start_link(%Config{} = config) do
    Logger.debug(["Starting new formula websocket client, ", inspect(config)])

    GenSocketClient.start_link(
      __MODULE__,
      Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
      config
    )
  end

  @impl true
  def init(%Config{} = config) do
    {:connect, config.url, [], %{config: config}}
  end

  @impl true
  def handle_connected(transport, state) do
    Logger.debug("Formular client connected to the server.")
    formulas = state.config.formulas || []

    case formulas do
      [_ | _] ->
        subscribe(formulas, transport, state)

      [] ->
        Logger.warn("Empty formula list.")
        {:stop, :normal, state}
    end
  end

  @impl true
  def handle_disconnected(reason, state) do
    Logger.error(["Formular client disconnected, reason: ", inspect(reason)])
    :timer.sleep(@reconnect_delay)
    {:connect, state}
  end

  @impl true
  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.warn("reply on topic #{topic}: #{inspect(payload)}")
    {:ok, state}
  end

  @impl true
  def handle_message(<<"formula:", name::binary>>, _, %{"code" => code}, _transport, state) do
    Logger.debug(["Received new code form #{name}: ", inspect(code)])

    case handle_new_code_revision(name, code, state.config) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  def handle_message(topic, event, payload, _transport, state) do
    Logger.warn("Unhandled message on topic #{topic}: #{event} #{inspect(payload)}")
    {:ok, state}
  end

  @impl true
  def handle_joined(topic, _payload, _transport, state) do
    Logger.info(["Formular client joined channel: ", topic])
    {:ok, state}
  end

  @impl true
  def handle_join_error(topic, payload, _transport, state) do
    Logger.error("Formular client join error on the topic #{topic}: #{inspect(payload)}")
    {:stop, :error_joined, state}
  end

  @impl true
  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("disconnected from the topic #{topic}: #{inspect(payload)}")
    Process.send_after(self(), {:join, topic}, :timer.seconds(1))
    {:ok, state}
  end

  @impl true
  def handle_info(_msg, _transport, state) do
    {:ok, state}
  end

  @impl true
  def handle_call(message, _from, _transport, state) do
    Logger.warn("Did not expect to receive call with message: #{inspect(message)}")
    {:reply, {:error, :unexpected_message}, state}
  end

  defp subscribe([{_mod, name, _context} | rest], transport, state) do
    topic = formula_topic(name)
    {:ok, _ref} = GenSocketClient.join(transport, topic, join_payload(state.config))
    subscribe(rest, transport, state)
  end

  defp subscribe([], _transport, state) do
    {:ok, state}
  end

  defp formula_topic(formula_name) do
    "formula:#{formula_name}"
  end

  defp join_payload(%{client_name: client_name}) do
    %{client_name: client_name}
  end

  def handle_new_code_revision(name, code, config) do
    case Config.formula_config(config, name) do
      {nil, ^name, _} ->
        true = Formular.Client.Cache.put(name, code)
        :ok

      {mod, ^name, _} when is_atom(mod) ->
        Formular.Client.Compiler.handle_new_code_revision(name, code, config)
        true = Formular.Client.Cache.put(name, mod)
        :ok
    end
  end
end
