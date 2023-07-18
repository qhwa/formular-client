defmodule Formular.ClientTest do
  alias Formular.Client.Cache
  use ExUnit.Case

  import Formular.Client.Adapter.Mock, only: [mock_global: 2]
  import Formular.Client, only: [eval: 2]

  doctest Formular.Client

  describe "start, set and eval" do
    setup do
      {:ok, name: "foo", secret: :rand.uniform(100)}
    end

    setup [:start_client]

    test "it works", %{name: name, secret: secret} do
      assert eval(name, []) == {:ok, secret}
    end

    test "it accepts string code", %{name: name} do
      mock_global(name, ":test")
      assert eval(name, []) == {:ok, :test}
    end

    test "it accepts modules", %{name: name} do
      Cache.put(name, TestFm)
      assert eval(name, []) == {:ok, :module}
    end

    test "it raises an error when code is not available" do
      assert_raise(
        RuntimeError,
        "Code has not been fetched",
        fn ->
          eval("NON-EXISTS", [])
        end
      )
    end
  end

  describe "Invalid adapter config" do
    test "it raises an error." do
      Process.flag(:trap_exit, true)

      assert {:error, _} =
               Formular.Client.Supervisor.start_link(adapter: {"some invalid config", "test"})
    end
  end

  defp start_client(%{name: name, secret: secret}) do
    {:ok, pid} =
      Formular.Client.Supervisor.start_link(
        adapter:
          {Formular.Client.Adapter.Mock,
           formulas: [
             {name, fn _, _ -> secret end}
           ]}
      )

    on_exit(fn ->
      Process.exit(pid, :killed)
    end)

    :ok
  end
end

defmodule TestFm do
  def run(_binding) do
    :module
  end
end
