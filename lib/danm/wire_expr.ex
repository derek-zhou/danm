defmodule Danm.WireExpr do
  @moduledoc """
  WireExpr is expression with width, used in constructing hardware model.
  """

  use Bitwise, only_operators: true

  @doc """
  width(ast)
  return the width of the ast
  """
  def width(x), do: width(x, in: %{})

  @doc """
  width(ast, in: context)
  return the width of the ast inside the context
  """
  def width(:defult, in: _), do: nil
  def width({:const, w, _}, in: _), do: w
  def width({:dup, sub, times}, in: con), do: times * width(sub, in: con)
  def width({:ext, _, msb, lsb, step}, in: _), do: div((lsb - msb), step) + 1
  # FIXME:
  def width({:id, _}, in: _), do: 32
  
  # unary operators
  def width({:bit_not, sub}, in: con), do: width(sub, in: con)
  def width({:negate, sub}, in: con), do: width(sub, in: con)
  def width({:log_not, _}, in: _), do: 1
  def width({:bit_and, _}, in: _), do: 1
  def width({:bit_or, _}, in: _), do: 1
  def width({:bit_xor, _}, in: _), do: 1

  # binary operators
  def width({:add, l, r}, in: con), do: max_width(l, r, con)
  def width({:sub, l, r}, in: con), do: max_width(l, r, con)
  def width({:bit_and, l, r}, in: con), do: max_width(l, r, con)
  def width({:bit_or, l, r}, in: con), do: max_width(l, r, con)
  def width({:bit_xor, l, r}, in: con), do: max_width(l, r, con)
  def width({:equal, _, _}, in: _), do: 1
  def width({:greater, _, _}, in: _), do: 1
  def width({:less, _, _}, in: _), do: 1
  def width({:not_greater, _, _}, in: _), do: 1
  def width({:not_less, _, _}, in: _), do: 1
  def width({:unequal, _, _}, in: _), do: 1
  def width({:log_and, _, _}, in: _), do: 1
  def width({:log_or, _, _}, in: _), do: 1
  def width({:log_xor, _, _}, in: _), do: 1
  def width({:comma, l, r}, in: con), do: sum_width(l, r, con)

  # compound operators
  def width({:bundle, items}, in: con), do: sum_width(items, con)
  def width({:bundle_or, items}, in: con), do: max_width(items, con)
  def width({:bundle_and, items}, in: con), do: max_width(items, con)
  def width({:bundle_xor, items}, in: con), do: max_width(items, con)
  def width({:choice, _, choices}, in: con), do: max_width(choices, con)
  def width({:ifs, _, choices}, in: con), do: max_width(choices, con)
  def width({:cases, _, _, choices}, in: con), do: max_width(choices, con)

  defp sum_width(l, r, con), do: width(l, in: con) + width(r, in: con)
  defp sum_width(items, con), do: Enum.reduce(items, 0, &(width(&1, in: con) + &2))
  defp max_width(l, r, con), do: max(width(l, in: con), width(r, in: con))
  defp max_width(items, con), do: Enum.reduce(items, 0, &(max(width(&1, in: con), &2)))

  @doc """
  ast_string(ast)
  return a string representation of ast
  """
  def ast_string(:defult), do: "default"
  def ast_string({:const, 0, v}), do: to_string(v)
  def ast_string({:const, w, v}), do: "#{w}'d#{v}"
  # FIXME
  def ast_string({:id, name}), do: name
  def ast_string({:dup, sub, times}), do: "{#{times}{#{ast_string(sub)}}}"
  def ast_string({:ext, sub, msb, lsb, -1}), do: "#{ast_string(sub)}[#{msb}:#{lsb}]"
  def ast_string({:ext, sub, msb, lsb, step}), do: "#{ast_string(sub)}[#{msb}:#{lsb}:#{step}]"
  
  # unary operators
  def ast_string({:bit_not, sub}), do: "(~ #{ast_string(sub)})"
  def ast_string({:negate, sub}), do: "(- #{ast_string(sub)})"
  def ast_string({:log_not, sub}), do: "(! #{ast_string(sub)})"
  def ast_string({:bit_and, sub}), do: "(& #{ast_string(sub)})"
  def ast_string({:bit_or, sub}), do: "(| #{ast_string(sub)})"
  def ast_string({:bit_xor, sub}), do: "(^ #{ast_string(sub)})"

  # binary operators
  def ast_string({:add, l, r}), do: "(#{ast_string(l)} + #{ast_string(r)})"
  def ast_string({:sub, l, r}), do: "(#{ast_string(l)} - #{ast_string(r)})"
  def ast_string({:bit_and, l, r}), do: "(#{ast_string(l)} & #{ast_string(r)})"
  def ast_string({:bit_or, l, r}), do: "(#{ast_string(l)} | #{ast_string(r)})"
  def ast_string({:bit_xor, l, r}), do: "(#{ast_string(l)} ^ #{ast_string(r)})"
  def ast_string({:equal, l, r}), do: "(#{ast_string(l)} == #{ast_string(r)})"
  def ast_string({:greater, l, r}), do: "(#{ast_string(l)} > #{ast_string(r)})"
  def ast_string({:less, l, r}), do: "(#{ast_string(l)} < #{ast_string(r)})"
  def ast_string({:not_greater, l, r}), do: "(#{ast_string(l)} <= #{ast_string(r)})"
  def ast_string({:not_less, l, r}), do: "(#{ast_string(l)} >= #{ast_string(r)})"
  def ast_string({:unequal, l, r}), do: "(#{ast_string(l)} != #{ast_string(r)})"
  def ast_string({:log_and, l, r}), do: "(#{ast_string(l)} && #{ast_string(r)})"
  def ast_string({:log_or, l, r}), do: "(#{ast_string(l)} || #{ast_string(r)})"
  def ast_string({:log_xor, l, r}), do: "(#{ast_string(l)} ^^ #{ast_string(r)})"
  def ast_string({:comma, l, r}), do: "(#{ast_string(l)} , #{ast_string(r)})"

  # compound operators
  def ast_string({:bundle, items}), do: "{#{ast_string_bundle_inner(",", items)}}"
  def ast_string({:bundle_or, items}), do: "(#{ast_string_bundle_inner("|", items)})"
  def ast_string({:bundle_and, items}), do: "(#{ast_string_bundle_inner("&", items)})"
  def ast_string({:bundle_xor, items}), do: "(#{ast_string_bundle_inner("^", items)})"

  # FIXME: catch all
  def ast_string(t), do: inspect(t)

  defp ast_string_bundle_inner(_, []), do: ""
  defp ast_string_bundle_inner(_, [head]), do: ast_string(head)
  defp ast_string_bundle_inner(op, [head | tail]) do
    ast_string(head) <> op <> ast_string_bundle_inner(op, tail)
  end

  @doc """
  parse(str)
  parse the str
  orders of operator precedance:

   1. dup (*) extract[::]
   2. unary operator
   4. binary operators with 2 chars: == != >= <= && || ^^
   3. binary operator with single char: +-&|^,><
   5, ?::

   The above order is important, so that a && b will be (a && b) not (a & (&b))

  """
  def parse(s) do
    {e, s} = parse_expr(s)
    if String.length(s) > 0, do: raise "Garbage at the end: #{s}"
    e
  end

  defp parse_expr(s) do
    {condition, s} = parse_segment(s)
    case expect_token(s, "?") do
      {:error, s} -> {condition, s}
      {:ok, s} ->
	{first, s} = parse_segment(s)
	{choices, s} = parse_choices_chain(s)
	{{:choice, condition, [first | choices]}, s}
    end
  end

  defp expect_token!(s, t) do
    s = String.trim_leading(s)
    {first, rest} = String.split_at(s, 1)
    if first == t, do: rest, else: raise "expect token #{t} at #{s}"
  end
      
  defp expect_token(s, t) do
    s = String.trim_leading(s)
    {first, rest} = String.split_at(s, 1)
    if first == t, do: {:ok, rest}, else: {:error, s}
  end

  defp skip_token(s, t), do: elem(expect_token(s, t), 1)

  defp parse_choices_chain(s) do
    case expect_token(s, ":") do
      {:error, s} -> {[], s}
      {:ok, s} ->
	{this, s} = parse_segment(s)
	{rest, s} = parse_choices_chain(s)
	{[this | rest], s}
    end
  end

  defp parse_segment(s) do
    {l, s} = parse_segment_higher(s)
    parse_segment_chain(s, inject: l)
  end

  defp parse_segment_chain(s, inject: term) do
    case parse_binary_single_op(s) do
      {:error, s} -> {term, s}
      {o, s} ->
	{l, s} = parse_segment_higher(s)
	parse_segment_chain(s, inject: {o, term, l})
    end
  end

  defp parse_segment_higher(s) do
    {l, s} = parse_term(s)
    parse_segment_higher_chain(s, inject: l)
  end

  defp parse_segment_higher_chain(s, inject: term) do
    case parse_binary_double_op(s) do
      {:error, s} -> {term, s}
      {o, s} ->
	{l, s} = parse_term(s)
	parse_segment_higher_chain(s, inject: {o, term, l})
    end
  end

  defp parse_binary_double_op(s) do
    case String.trim_leading(s) do
      "==" <> s -> {:equal, s}
      "!=" <> s -> {:unequal, s}
      ">=" <> s -> {:not_less, s}
      "<=" <> s -> {:not_greater, s}
      "&&" <> s -> {:log_and, s}
      "||" <> s -> {:log_or, s}
      "^^" <> s -> {:log_xor, s}
      s -> {:error, s}
    end
  end

  defp parse_binary_single_op(s) do
    case String.trim_leading(s) do
      ">" <> s -> {:greater, s}
      "<" <> s -> {:less, s}
      "," <> s -> {:comma, s}
      "+" <> s -> {:add, s}
      "-" <> s -> {:sub, s}
      "&" <> s -> {:bit_and, s}
      "|" <> s -> {:bit_or, s}
      "^" <> s -> {:bit_xor, s}
      s -> {:error, s}
    end
  end

  defp parse_unary_op(s) do
    case String.trim_leading(s) do
      "-" <> s -> {:negate, s}
      "!" <> s -> {:log_not, s}
      "~" <> s -> {:bit_not, s}
      "&" <> s -> {:bit_and, s}
      "|" <> s -> {:bit_or, s}
      "^" <> s -> {:bit_xor, s}
      s -> {:error, s}
    end
  end

  defp parse_term(s) do
    case parse_unary_op(s) do
      {:error, s} -> parse_mod_term(s)
      {o, s} ->
	{l, s} = parse_term(s)
	{{o, l}, s}
    end
  end

  defp parse_mod_op(s) do
    case String.trim_leading(s) do
      "*" <> s -> {:dup, s}
      "[" <> s -> {:ext, s}
      s -> {:error, s}
    end
  end

  defp expect_integer!(s) do
    case Integer.parse(String.trim_leading(s)) do
      {n, s} when is_integer(n) -> {n, s}
      :error -> raise "Expect interger at: #{s}"
    end
  end

  defp parse_mod_term(s) do
    {sub, s} = parse_factor(s)
    case parse_mod_op(s) do
      {:error, s} -> {sub, s}
      {:dup, s} ->
	{n, s} = expect_integer!(s)
	{{:dup, sub, n}, s}
      {:ext, s} ->
	{msb, s} = expect_integer!(s)
	s = expect_token!(s, ":")
	{lsb, s} = expect_integer!(s)
	case expect_token(s, ":") do
	  {:error, s} -> {{:ext, sub, msb, lsb, -1}, expect_token!(s, "]")}
	  {:ok, s} ->
	    {step, s} = expect_integer!(s)
	    {{:ext, sub, msb, lsb, step}, expect_token!(s, "]")}
	end
    end	
  end

  defp parse_factor(s) do
    case String.trim_leading(s) do
      "(" <> s -> parse_paren(s)
      s ->
	case Integer.parse(s) do
	  {n, s} when is_integer(n) -> parse_constant(s, n)
	  :error -> parse_identifier(s)
	end
    end
  end

  defp parse_paren(s) do
    {e, s} = parse_expr(s)
    case String.trim_leading(s) do
      ")" <> s -> {e, s}
      s -> raise "Expect ), got: #{s}"
    end
  end

  defp parse_identifier(s) do
    case Regex.run(~r/^(\w+)(.*)/, s) do
      [_, first, rest] -> {{:id, first}, rest}
      _ -> raise "Expect identifier in #{s}"
    end
  end

  defp parse_radix(s) do
    case String.trim_leading(s) do
      "b" <> s -> {2, s}
      "B" <> s -> {2, s}
      "o" <> s -> {8, s}
      "O" <> s -> {8, s}
      "h" <> s -> {16, s}
      "H" <> s -> {16, s}
      "d" <> s -> {10, s}
      "D" <> s -> {10, s}
      s -> {:error, s}
    end
  end

  # TODO: original code supports _ as spacer
  def parse_constant(s, width) do
    s = skip_token(s, "'")
    case parse_radix(s) do
      {:error, s} -> {{:const, nil, width}, s}
      {r, s} ->
	case Integer.parse(s, r) do
	  {n, s} when is_integer(n) -> {{:const, width, n}, s}
	  :error -> raise "Expect integer, got: #{s}"
	end
    end
  end
  
end
