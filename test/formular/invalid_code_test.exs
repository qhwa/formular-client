defmodule Formular.Client.InvalidCodeTest do
  alias Formular.Client.Config

  use ExUnit.Case, async: false
  require Logger

  setup do
    {:ok,
     config:
       Config.new(
         client_name: "websocket_test",
         url: "ws://localhost:1500/socket/websocket",
         formulas: [{:invalid_fm, "invalid_formula"}]
       )}
  end

  setup [:subscribe, :start_client]

  describe "Invalid code" do
    test "should not crash the application" do
      assert :invalid_fm.run([]) == "invalid_formula"

      formula = %{
        name: "invalid_formula",
        # `foo` is undefined
        code: "foo()"
      }

      Phoenix.PubSub.broadcast(
        TestSite.PubSub,
        "formula:invalid_formula",
        {:update, formula}
      )

      refute_receive {:code_change, "invalid_formula", _, "foo()"}, 1_000
      assert_receive {:compile_failed, "invalid_formula", _, "foo()", _}, 1_000

      assert :invalid_fm.run([]) == "invalid_formula"
      assert Formular.Client.eval("invalid_formula", []) == {:ok, "invalid_formula"}
    end
  end

  defp start_client(%{config: config}) do
    {:ok, _client} = Formular.Client.Supervisor.start_link(config)

    :ok
  end

  defp subscribe(%{config: %{formulas: formulas}}) do
    pid = self()

    for {f, _} <- formulas,
        do: :ok = Formular.Client.PubSub.subscribe(f)

    on_exit(fn ->
      for {f, _} <- formulas,
          Process.alive?(pid),
          do: :ok = Formular.Client.PubSub.unsubscribe(f, pid)
    end)

    :ok
  end
end
