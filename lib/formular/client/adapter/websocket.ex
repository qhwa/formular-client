defmodule Formular.Client.Adapter.Websocket do
  @moduledoc """
  The default adapter for maintaining a two-way connection between
  the client and remote server, using WebSocket.
  """

  alias Formular.Client.Cache
  alias Formular.Client.Compiler
  alias Formular.Client.Config
  alias Formular.Client.PubSub
  alias Phoenix.Channels.GenSocketClient

  @behaviour GenSocketClient
  @reconnect_delay :timer.seconds(5)

  require Logger
  import GenSocketClient, only: [push: 4]

  def start_link(%Config{} = config, _options) do
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
  def handle_message(<<"formula:", name::binary>> = topic, _, %{"code" => code}, transport, state) do
    Logger.debug(["Received new code form #{name}: ", inspect(code)])

    old_code = current_code(name)

    with :ok <- handle_new_code_revision(name, code, state.config),
         :ok <- dispatch_code_change(name, old_code, code),
         {:ok, _} <- push(transport, topic, "code_updated", %{}) do
      {:ok, state}
    else
      err ->
        Logger.error("Error compiling code for #{name}, reason: #{inspect(err)}")

        case try_report_err(transport, topic, err) do
          {:ok, _} ->
            {:ok, state}

          {:error, reason} ->
            Logger.error(
              "Failed on reporting compilation error to server, error: #{inspect(reason)}."
            )

            {:stop, reason, state}
        end
    end
  end

  def handle_message(topic, event, payload, _transport, state) do
    Logger.warn("Unhandled message on topic #{topic}: #{event} #{inspect(payload)}")
    {:ok, state}
  end

  defp try_report_err(transport, topic, {:error, %CompileError{description: reason}}) do
    push(transport, topic, "code_update_error", %{reason: ["compile_error", reason]})
  end

  defp try_report_err(transport, topic, {:error, :unknown_compile_error}) do
    push(transport, topic, "code_update_error", %{
      reason: ["compile_error", "unknown_compile_error"]
    })
  end

  defp try_report_err(_, _, err),
    do: err

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

  defp current_code(name) do
    case Cache.get(name) do
      {mod, code} when is_atom(mod) and is_binary(code) ->
        code

      other ->
        other
    end
  end

  def handle_new_code_revision(name, code, config) do
    case Config.formula_config(config, name) do
      {nil, ^name, _} ->
        true = Cache.put(name, code)
        :ok

      {mod, ^name, _} when is_atom(mod) ->
        ref = make_ref()
        :ok = Compiler.handle_new_code_revision({self(), ref}, name, code, config)

        receive do
          {^ref, :ok} ->
            true = Cache.put(name, {mod, code})
            :ok

          {^ref, err} ->
            err
        after
          5_000 ->
            {:error, :unknown_compile_error}
        end

      nil ->
        {:error, :formula_not_found}
    end
  end

  defp dispatch_code_change(name, old_code, new_code) do
    PubSub.dispatch_code_change(name, old_code, new_code)
  end
end
