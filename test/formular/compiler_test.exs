defmodule Formular.Client.CompilerTest do
  alias Formular.Client.Compiler
  alias Formular.Client.Config

  use ExUnit.Case, async: true

  setup do
    opts = [compile_as: DiscountFm]

    config =
      Config.new(%{
        formulas: [
          {"discount", opts}
        ]
      })

    {:ok, config: config, opts: opts}
  end

  describe "handle_new_code_revision/3" do
    test "it works", %{config: config, opts: opts} do
      ref = make_ref()
      Compiler.handle_new_code_revision({self(), ref}, "discount", "0.5", config, opts)

      assert_receive {^ref, :ok}
      assert apply(DiscountFm, :run, [[]]) == 0.5
    end

    test "it works with custom function", %{config: config, opts: opts} do
      parent = self()

      compiler = fn {code, name, opts} ->
        send(parent, {code, name, opts})
        :ok
      end

      ref = make_ref()

      config = %{config | compiler: compiler}
      Compiler.handle_new_code_revision({parent, ref}, "discount", "0.9", config, opts)

      assert_receive {^ref, :ok}, 1_000
      assert_receive {"0.9", "discount", ^opts}, 1_000
    end
  end
end
