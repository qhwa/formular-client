defmodule Formular.Client.ConfigTest do
  alias Formular.Client.Config

  use ExUnit.Case, async: true

  describe "new/1" do
    test "it works" do
      assert %Config{} = Config.new(%{})
    end

    test "it works with formulas" do
      config =
        Config.new(%{
          formulas: [
            "test",
            {MyFm, "my-fm"},
            {AnotherFm, "another-fm", MyHelper}
          ]
        })

      assert config.formulas == [
               {nil, "test", nil},
               {MyFm, "my-fm", nil},
               {AnotherFm, "another-fm", MyHelper}
             ]
    end
  end

  describe "formula_config/2" do
    setup do
      config =
        Config.new(%{
          formulas: [
            "foo"
          ]
        })

      {:ok, config: config}
    end

    test "it get the config if it exists", %{config: config} do
      assert Config.formula_config(config, "foo") == {nil, "foo", nil}
    end

    test "it returns nil when missing", %{config: config} do
      assert Config.formula_config(config, "bar") == nil
    end
  end
end
