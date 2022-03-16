defmodule Formular.ClientTest do
  use ExUnit.Case
  doctest Formular.Client

  describe "start, set and eval" do
    setup do
      {:ok, name: "foo", secret: :rand.uniform(100)}
    end

    setup [:start_client]

    test "it works", %{name: name, secret: secret} do
      assert Formular.Client.eval(name, []) == {:ok, secret}
    end
  end

  defp start_client(%{name: name, secret: secret}) do
    {:ok, _pid} =
      Formular.Client.Supervisor.start_link(
        adapter:
          {Formular.Client.Adapter.Mock,
           formulas: [
             {name, fn _, _ -> secret end}
           ]}
      )

    :ok
  end
end
