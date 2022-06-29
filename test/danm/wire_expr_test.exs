defmodule Danm.WireExprTest do
  use ExUnit.Case
  import Danm.WireExpr

  doctest Danm.WireExpr

  defp parse_error(s) do
    assert_raise RuntimeError, fn -> parse(s) end
  end

  defp parse_success(s, expect: v) do
    assert(
      v ==
        s
        |> parse()
        |> ast_string(fn x -> x end)
    )
  end

  test "unmatched paren", do: parse_error("((a+b)*c")
  test "unparsable integer", do: parse_error("3d4AA+c")

  test "operator priority", do: parse_success("d&a&&b", expect: "(d & (a && b))")

  test "bin, dec, hex and oct" do
    parse_success("3d12,5b111,6o76,7h3F",
      expect: "{{{3'd12, 5'd7}, 6'd62}, 7'd63}"
    )
  end

  test "choice operator" do
    parse_success("a?b+c:b-c", expect: "(a ? (b + c) : (b - c))")
  end
end
