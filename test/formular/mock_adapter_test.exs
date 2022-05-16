defmodule Formular.Client.MockAdapterTest do
  alias Formular.Client.Adapter.Mock
  alias Formular.Client.Config

  use ExUnit.Case, async: true

  setup do
    config =
      Config.new(%{
        adapter: {
          Mock,
          formulas: [
            {"frequency", fn _, _ -> 30 end}
          ]
        }
      })

    {:ok, config: config}
  end

  describe "Mocked formulas" do
    test "it works", context do
      assert {:ok, _pid} = start_client(context)
    end
  end

  describe "Missing mocking" do
    setup %{config: config} do
      {:ok, config: %{config | formulas: [{nil, "foo", nil}]}}
    end

    test "it raises error when missing", context do
      Process.flag(:trap_exit, true)
      start_client(context)

      assert_receive {:EXIT, _pid, {:shutdown, _}}
    end
  end

  defp start_client(%{config: config}) do
    Formular.Client.Supervisor.start_link(config)
  end
end
