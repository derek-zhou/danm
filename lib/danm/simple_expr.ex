defmodule Danm.SimpleExpr do
  @moduledoc """
  SimpleExpr parse and evaluate expression with integers.
  """

  use Bitwise, only_operators: true

  @doc """
  eval(ast)
  evaluate ast without identifier map
  """
  def eval(n), do: eval(n, in: %{})
  @doc """
  eval(ast, in: dict)
  evaluate ast with identifier map in: dict
  """
  def eval(n, in: _) when is_integer(n), do: n
  def eval(s, in: dict) when is_binary(s), do: Map.fetch!(dict, s)
  def eval({:add, l, r}, in: dict), do: eval(l, in: dict) + eval(r, in: dict)
  def eval({:sub, l, r}, in: dict), do: eval(l, in: dict) - eval(r, in: dict)
  def eval({:mul, l, r}, in: dict), do: eval(l, in: dict) * eval(r, in: dict)
  def eval({:div, l, r}, in: dict), do: div(eval(l, in: dict), eval(r, in: dict))
  def eval({:rem, l, r}, in: dict), do: rem(eval(l, in: dict), eval(r, in: dict))
  def eval({:ls,  l, r}, in: dict), do: eval(l, in: dict) <<< eval(r, in: dict)
  def eval({:rs,  l, r}, in: dict), do: eval(l, in: dict) >>> eval(r, in: dict)

  @doc """
  ast_string(ast)
  return a string representation of ast
  """
  def ast_string(n) when is_integer(n), do: to_string(n)
  def ast_string(s) when is_binary(s), do: s

  def ast_string({op, l, r}) do
    op_table = %{add: "+",
		 sub: "-",
		 mul: "*",
		 div: "/",
		 rem: "%",
		 ls: "<<",
		 rs: ">>"}
    "(#{ast_string(l)} #{Map.fetch!(op_table, op)} #{ast_string(r)})"
  end

  @doc """
  optimize(ast)
  try to optimize the ast
  """
  def optimize(n) when is_integer(n), do: n
  def optimize(s) when is_binary(s), do: s

  def optimize({op, l, r}) do
    {l, r} = {optimize(l), optimize(r)}
    if is_integer(l) and is_integer(r) do
      eval({op, l, r})
    else
      case {op, l, r} do
	{:add, 0, x} -> x
	{:add, x, 0} -> x
	{:sub, x, 0} -> x
	{:mul, 0, _} -> 0
	{:mul, _, 0} -> 0
	{:mul, 1, x} -> x
	{:mul, x, 1} -> x
	{:div, 0, _} -> 0
	{:div, x, 1} -> x
	{:rem, 0, _} -> 0
	{:ls,  0, _} -> 0
	{:ls,  x, 0} -> x
	{:rs,  0, _} -> 0
	{:rs,  x, 0} -> x
	_ -> {op, l, r}
      end
    end
  end

  @doc """
  parse(str)
  parse the str without identifier dict
  3 orders of operator precedance:

   1. * / %
   2. + -
   3. << >>

  """
  def parse(s), do: parse(s, with: %{})

  @doc """
  parse(str with: dict)
  parse the str with identifier dict
  3 orders of operator precedance:

   1. * / %
   2. + -
   3. << >>

  """
  def parse(s, with: dict) do
    {e, s} = parse_order1(s, with: dict)
    if String.length(s) > 0, do: raise "Garbage at the end: #{s}"
    e
  end

  defp parse_order1(s, with: dict) do
    {l, s} = parse_order2(s, with: dict)
    {chain, s} = parse_order1_chain(s, with: dict)
    {Enum.reduce(chain, l, &({elem(&1, 0), &2, elem(&1, 1)})), s}
  end

  defp parse_order1_chain(s, with: dict) do
    case parse_order1_op(s) do
      {:error, s} -> {[], s}
      {o, s} ->
	{l, s} = parse_order2(s, with: dict)
	{chain, s} = parse_order1_chain(s, with: dict)
	{[{o, l}] ++ chain, s}
    end
  end

  defp parse_order1_op(s) do
    case String.trim_leading(s) do
      "<<" <> s -> {:ls, s}
      ">>" <> s -> {:rs, s}
      s -> {:error, s}
    end
  end

  defp parse_order2(s, with: dict) do
    {l, s} = parse_order3(s, with: dict)
    {chain, s} = parse_order2_chain(s, with: dict)
    {Enum.reduce(chain, l, &({elem(&1, 0), &2, elem(&1, 1)})), s}
  end

  defp parse_order2_chain(s, with: dict) do
    case parse_order2_op(s) do
      {:error, s} -> {[], s}
      {o, s} ->
	{l, s} = parse_order3(s, with: dict)
	{chain, s} = parse_order2_chain(s, with: dict)
	{[{o, l}] ++ chain, s}
    end
  end

  defp parse_order2_op(s) do
    case String.trim_leading(s) do
      "+" <> s -> {:add, s}
      "-" <> s -> {:sub, s}
      s -> {:error, s}
    end
  end

  defp parse_order3(s, with: dict) do
    {l, s} = parse_factor(s, with: dict)
    {chain, s} = parse_order3_chain(s, with: dict)
    {Enum.reduce(chain, l, &({elem(&1, 0), &2, elem(&1, 1)})), s}
  end

  defp parse_order3_chain(s, with: dict) do
    case parse_order3_op(s) do
      {:error, s} -> {[], s}
      {o, s} ->
	{l, s} = parse_factor(s, with: dict)
	{chain, s} = parse_order3_chain(s, with: dict)
	{[{o, l}] ++ chain, s}
    end
  end

  defp parse_order3_op(s) do
    case String.trim_leading(s) do
      "*" <> s -> {:mul, s}
      "/" <> s -> {:div, s}
      "%" <> s -> {:rem, s}
      s -> {:error, s}
    end
  end

  defp parse_factor(s, with: dict) do
    case String.trim_leading(s) do
      "(" <> s -> parse_paren(s, with: dict)
      s ->
	case Integer.parse(s) do
	  {n, s} when is_integer(n) -> {n, s}
	  :error -> parse_identifier(s, with: dict)
	end
    end
  end

  defp parse_paren(s, with: dict) do
    {e, s} = parse_order1(s, with: dict)
    case String.trim_leading(s) do
      ")" <> s -> {e, s}
      s -> raise "Expect ), got: #{s}"
    end
  end

  defp parse_identifier(s, with: dict) do
    {first, rest} = parse_identifier_token(s)
    case Map.fetch(dict, first) do
      {:ok, _} -> {first, rest}
      _ -> raise "Unknown identifier #{first}"
    end
  end

  defp parse_identifier_token(s) do
    case Regex.run(~r/^(\w+)(.*)/, s) do
      [_, first, rest] -> {first, rest}
      _ -> raise "Cannot find identifier in #{s}"
    end
  end
end
