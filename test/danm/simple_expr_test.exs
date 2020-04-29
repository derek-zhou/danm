defmodule Danm.SimpleExprTest do
  use ExUnit.Case
  import Danm.SimpleExpr

  doctest Danm.SimpleExpr

  defp parse_error(s, with: dict) do
    assert_raise RuntimeError, fn ->
      parse(s, with: dict)
    end
  end

  defp parse_success(s, with: dict, expect: v) do
    assert v ==
      parse(s, with: dict)
      |> optimize()
      |> eval(in: dict)
  end

  test "unfound identifier" do
    parse_error "(a+b)*c", with: %{"a"=>2, "b"=>3}
  end

  test "add and mul" do
    parse_success "(-1+b)*c-a", with: %{"a"=>2, "b"=>3, "c"=>5}, expect: 8
  end

  test "negation" do
    parse_success "(b-a)*c", with: %{"a"=>-2, "b"=>3, "c"=>5}, expect: 25
  end

  test "long chain" do
    parse_success "5-3-2-1-7", with: %{}, expect: -8
  end

end
