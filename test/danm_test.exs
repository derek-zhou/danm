defmodule DanmTest do
  use ExUnit.Case
  doctest Danm

  test "greets the world" do
    assert Danm.hello() == :world
  end
end
