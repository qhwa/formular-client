defmodule Formular.Client.Adapter.WebsocketTest do
  use ExUnit.Case, async: false

  alias TestSite.Endpoint

  setup do
    {:ok, port: :rand.uniform(10_000) + 10_000}
  end

  setup do
    {:ok,
     formulas: [
       "a",
       "b",
       {FooFm, "foo"}
     ]}
  end

  setup %{port: port} do
    Endpoint.start_link(http: [port: port])
    :ok
  end

  setup [:start_client]

  describe "Fetch and compile" do
    test "connection success" do
      assert Formular.Client.eval("a", []) == {:ok, "a"}
    end
  end

  describe "Connect and watch" do
    test "it updates client code on server-side update" do
      formula = %{
        name: "b",
        code: "1000"
      }

      Phoenix.PubSub.broadcast(
        TestSite.PubSub,
        "formula:b",
        {:update, formula}
      )

      :timer.sleep(200)

      assert Formular.Client.eval("b", []) == {:ok, 1000}
    end

    test "it re-compiles on server-side update" do
      formula = %{
        name: "foo",
        code: ":bar"
      }

      Phoenix.PubSub.broadcast(
        TestSite.PubSub,
        "formula:foo",
        {:update, formula}
      )

      :timer.sleep(200)

      assert Formular.Client.eval("foo", []) == {:ok, :bar}
    end
  end

  defp start_client(%{port: port, formulas: formulas}) do
    {:ok, _client} =
      Formular.Client.Supervisor.start_link(
        client_name: "websocket_test",
        url: "ws://localhost:#{port}/socket/websocket",
        formulas: formulas
      )

    :ok
  end
end
