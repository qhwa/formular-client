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
      Compiler.handle_new_code_revision("discount", "0.5", config)

      assert DiscountFm.run([]) == 0.5
    end

    test "it works with custom function", %{config: config} do
      compiler = fn {code, name, module, context} ->
        send(self(), {code, name, module, context})
      end

      config = %{config | compiler: compiler}
      Compiler.handle_new_code_revision("discount", "0.9", config)

      assert_receive {"0.9", "discount", DiscountFm, nil}
    end
  end
end
