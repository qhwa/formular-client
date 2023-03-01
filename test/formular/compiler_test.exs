defmodule Formular.Client.CompilerTest do
  alias Formular.Client.Compiler
  alias Formular.Client.Config

  use ExUnit.Case, async: true

  setup do
    config =
      Config.new(%{
        formulas: [
          {DiscountFm, "discount"}
        ]
      })

    {:ok, config: config}
  end

  describe "handle_new_code_revision/3" do
    test "it works", %{config: config} do
      ref = make_ref()
      Compiler.handle_new_code_revision({self(), ref}, "discount", "0.5", config)

      assert_receive {^ref, :ok}
      assert DiscountFm.run([]) == 0.5
    end

    test "it works with custom function", %{config: config} do
      parent = self()

      compiler = fn {code, name, module, context} ->
        send(parent, {code, name, module, context})
        :ok
      end

      ref = make_ref()

      config = %{config | compiler: compiler}
      Compiler.handle_new_code_revision({self(), ref}, "discount", "0.9", config)

      assert_receive {^ref, :ok}
      assert_receive {"0.9", "discount", DiscountFm, nil}
    end
  end
end
