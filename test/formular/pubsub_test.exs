defmodule Formular.Client.PubSubTest do
  alias Formular.Client.Config
  alias Formular.Client.PubSub
  use ExUnit.Case, async: false

  alias TestSite.Endpoint

  setup do
    {:ok, port: :rand.uniform(10_000) + 10_000}
  end

  setup do
    {:ok, config: Config.new(formulas: ["a"])}
  end

  setup %{port: port} do
    Endpoint.start_link(http: [port: port])
    :ok
  end

  setup [:subscribe, :start_client]

  describe "Connect and watch" do
    test "it updates client code on server-side update" do
      formula = %{
        name: "a",
        code: "1000"
      }

      Phoenix.PubSub.broadcast(
        TestSite.PubSub,
        "formula:a",
        {:update, formula}
      )

      assert_receive {:code_change, "a", nil, ~s("a")}, 5_000
      assert_receive {:code_change, "a", ~s("a"), "1000"}, 5_000

      assert Formular.Client.eval("a", []) == {:ok, 1000}
    end
  end

  defp start_client(%{port: port, config: %{formulas: formulas}}) do
    {:ok, _client} =
      Formular.Client.Supervisor.start_link(
        client_name: "websocket_test",
        url: "ws://localhost:#{port}/socket/websocket",
        formulas: formulas
      )

    :ok
  end

  defp subscribe(%{config: %{formulas: formulas}}) do
    for {_, name, _} <- formulas, do: PubSub.subscribe(name)

    :ok
  end
end
