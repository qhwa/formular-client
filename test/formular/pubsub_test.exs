defmodule Formular.Client.PubSubTest do
  alias Formular.Client.Config
  alias Formular.Client.PubSub
  use ExUnit.Case, async: false

  @test_module __MODULE__.FM

  setup do
    {:ok,
     config:
       Config.new(
         client_name: "websocket_test",
         url: "ws://localhost:1500/socket/websocket",
         formulas: [
           "a",
           {@test_module, "test_module"},
           "unsubscribe"
         ]
       )}
  end

  setup [:subscribe, :start_client]

  describe "Receiving messages from PubSub" do
    test "works when server publishes events" do
      formula = %{
        name: "a",
        code: "1000"
      }

      Phoenix.PubSub.broadcast(
        TestSite.PubSub,
        "formula:a",
        {:update, formula}
      )

      assert_receive {:code_change, "a", ~s("a"), "1000"}, 5_000

      assert Formular.Client.eval("a", []) == {:ok, 1000}
    end

    test "works with modules" do
      Phoenix.PubSub.broadcast(
        TestSite.PubSub,
        "formula:test_module",
        {:update,
         %{
           name: "test_module",
           code: "1024"
         }}
      )

      assert_receive {:code_change, "test_module", ~s("test_module"), "1024"}, 5_000

      assert Formular.Client.eval("test_module", []) == {:ok, 1024}
    end
  end

  describe "Unscribing" do
    setup [:unsubscribe]

    test "works" do
      Phoenix.PubSub.broadcast(
        TestSite.PubSub,
        "formula:unsubscribe",
        {:update,
         %{
           name: "unsubscribe",
           code: "nil"
         }}
      )

      refute_receive {:code_change, "unsubscribe", ~s("unsubscribe"), "nil"}, 5_000
    end
  end

  defp start_client(%{config: config}) do
    {:ok, _client} = Formular.Client.Supervisor.start_link(config)

    :ok
  end

  defp subscribe(%{config: %{formulas: formulas}}) do
    for {_, name, _} <- formulas, do: PubSub.subscribe(name)

    :ok
  end

  defp unsubscribe(%{config: %{formulas: formulas}}) do
    for {_, name, _} <- formulas, do: PubSub.unsubscribe(name)

    :ok
  end
end
