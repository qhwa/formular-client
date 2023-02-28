defmodule Formular.Client.Adapter.WebsocketTest do
  alias Formular.Client.Config

  use ExUnit.Case, async: false
  require Logger

  setup do
    {:ok,
     config:
       Config.new(
         client_name: "websocket_test",
         url: "ws://localhost:1500/socket/websocket",
         formulas: [
           "a",
           "b",
           {FooFm, "foo"}
         ]
       )}
  end

  setup [:subscribe, :start_client]

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

      assert_receive {:code_change, "b", _, "1000"}, 5_000

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

      assert_receive {:code_change, "foo", _, ":bar"}, 5_000

      assert Formular.Client.eval("foo", []) == {:ok, :bar}
    end
  end

  defp start_client(%{config: config}) do
    {:ok, _client} = Formular.Client.Supervisor.start_link(config)

    :ok
  end

  defp subscribe(%{config: %{formulas: formulas}}) do
    pid = self()

    for {_, f, _} <- formulas,
        do: :ok = Formular.Client.PubSub.subscribe(f)

    on_exit(fn ->
      for {_, f, _} <- formulas,
          Process.alive?(pid),
          do: :ok = Formular.Client.PubSub.unsubscribe(f, pid)
    end)

    :ok
  end
end
