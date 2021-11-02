defmodule Formular.ClientTest do
  use ExUnit.Case
  doctest Formular.Client

  test "greets the world" do
    assert Formular.Client.hello() == :world
  end
end
