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
  valid?(ast)
  check ast without identifier map
  """
  def valid?(ast), do: valid?(ast, in: %{})

  @doc """
  valid?(ast, in: dict)
  check ast with identifier map in: dict
  """
  def valid?(n, in: _) when is_integer(n), do: true
  def valid?(s, in: dict) when is_binary(s), do: Map.has_key?(dict, s)
  def valid?({_, l, r}, in: dict), do: valid?(l, in: dict) and valid?(r, in: dict)

  @doc """
  ast_string(ast)
  return a string representation of ast
  """
  def ast_string(n) when is_integer(n), do: to_string(n)
  def ast_string(s) when is_binary(s), do: s
  def ast_string({:add, l, r}), do: "(#{ast_string(l)} + #{ast_string(r)})"
  def ast_string({:sub, l, r}), do: "(#{ast_string(l)} - #{ast_string(r)})"
  def ast_string({:mul, l, r}), do: "(#{ast_string(l)} * #{ast_string(r)})"
  def ast_string({:div, l, r}), do: "(#{ast_string(l)} / #{ast_string(r)})"
  def ast_string({:rem, l, r}), do: "(#{ast_string(l)} % #{ast_string(r)})"
  def ast_string({:ls,  l, r}), do: "(#{ast_string(l)} << #{ast_string(r)})"
  def ast_string({:rs,  l, r}), do: "(#{ast_string(l)} >> #{ast_string(r)})"

  @doc """
  optimize(ast)
  try to optimize the ast
  """
  def optimize(n) when is_integer(n), do: n
  def optimize(s) when is_binary(s), do: s

  def optimize({op, l, r}) do
    {l, r} = {optimize(l), optimize(r)}
    cond do
      is_integer(l) and is_integer(r) -> eval({op, l, r})
      true ->
	{op, l, r}
	|> try_swap()
	|> merge()
	|> short_circuit()
    end
  end

  defp short_circuit({op, l, r}) do
    case {op, l, r} do
      {:add, x, 0} -> x
      {:sub, x, 0} -> x
      {:mul, _, 0} -> 0
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


  defp try_swap({op, l, r}) do
    cond do
      is_integer(l) and !is_integer(r) and (op == :add or op == :mul) -> {op, r, l}
      true -> {op, l, r}
    end
  end

  defp merge({op, l, r}) do
    case {op, l, r} do
      {:add, {:add, ll, lr}, r} when is_integer(lr) and is_integer(r) -> {:add, ll, lr + r}
      {:add, {:sub, ll, lr}, r} when is_integer(lr) and is_integer(r) -> {:add, ll, r - lr}
      {:sub, {:add, ll, lr}, r} when is_integer(lr) and is_integer(r) -> {:add, ll, lr - r}
      {:sub, {:sub, ll, lr}, r} when is_integer(lr) and is_integer(r) -> {:sub, ll, lr + r}
      _ -> {op, l, r}
    end
  end

  @doc """
  parse(str)
  parse the str
  3 orders of operator precedance:

   1. `* / %`
   2. `+ -`
   3. `<< >>`

  """
  def parse(s) do
    {e, s} = parse_order1(s)
    if String.length(s) > 0, do: raise "Garbage at the end: #{s}"
    e
  end

  defp parse_order1(s) do
    {l, s} = parse_order2(s)
    parse_order1_chain(s, inject: l)
  end

  defp parse_order1_chain(s, inject: term) do
    case parse_order1_op(s) do
      {:error, s} -> {term, s}
      {o, s} ->
	{l, s} = parse_order2(s)
	parse_order1_chain(s, inject: {o, term, l})
    end
  end

  defp parse_order1_op(s) do
    case String.trim_leading(s) do
      "<<" <> s -> {:ls, s}
      ">>" <> s -> {:rs, s}
      s -> {:error, s}
    end
  end

  defp parse_order2(s) do
    {l, s} = parse_order3(s)
    parse_order2_chain(s, inject: l)
  end

  defp parse_order2_chain(s, inject: term) do
    case parse_order2_op(s) do
      {:error, s} -> {term, s}
      {o, s} ->
	{l, s} = parse_order3(s)
	parse_order2_chain(s, inject: {o, term, l})
    end
  end

  defp parse_order2_op(s) do
    case String.trim_leading(s) do
      "+" <> s -> {:add, s}
      "-" <> s -> {:sub, s}
      s -> {:error, s}
    end
  end

  defp parse_order3(s) do
    {l, s} = parse_factor(s)
    parse_order3_chain(s, inject: l)
  end

  defp parse_order3_chain(s, inject: term) do
    case parse_order3_op(s) do
      {:error, s} -> {term, s}
      {o, s} ->
	{l, s} = parse_factor(s)
	parse_order3_chain(s, inject: {o, term, l})
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

  defp parse_factor(s) do
    case String.trim_leading(s) do
      "(" <> s -> parse_paren(s)
      s ->
	case Integer.parse(s) do
	  {n, s} when is_integer(n) -> {n, s}
	  :error -> parse_identifier(s)
	end
    end
  end

  defp parse_paren(s) do
    {e, s} = parse_order1(s)
    case String.trim_leading(s) do
      ")" <> s -> {e, s}
      s -> raise "Expect ), got: #{s}"
    end
  end

  defp parse_identifier(s) do
    case Regex.run(~r/^(\w+)(.*)/, s) do
      [_, first, rest] -> {first, rest}
      _ -> raise "Cannot find identifier in #{s}"
    end
  end

end
