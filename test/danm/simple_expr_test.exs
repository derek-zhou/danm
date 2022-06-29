defmodule Danm.SimpleExprTest do
  use ExUnit.Case
  import Danm.SimpleExpr

  doctest Danm.SimpleExpr

  defp parse_error(s, in: dict) do
    refute(
      s
      |> parse()
      |> valid?(in: dict)
    )
  end

  defp parse_success(s, in: dict, expect: v) do
    assert(
      v ==
        s
        |> parse()
        |> optimize()
        |> eval(in: dict)
    )
  end

  test "unfound identifier" do
    parse_error("(a+b)*c", in: %{"a" => 2, "b" => 3})
  end

  test "add and mul" do
    parse_success("(-1+b)*c-a", in: %{"a" => 2, "b" => 3, "c" => 5}, expect: 8)
  end

  test "negation" do
    parse_success("(b-a)*c", in: %{"a" => -2, "b" => 3, "c" => 5}, expect: 25)
  end

  test "long chain" do
    parse_success("5-3-2-1-7", in: %{}, expect: -8)
  end
end
