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
  def width({:const, w, _}, in: _), do: w
  def width({:dup, sub, times}, in: con), do: times * width(sub, in: con)
  def width({:ext, _, msb, lsb, step}, in: _), do: div((lsb - msb), step) + 1
  # FIXME:
  def width({:id, id}, in: con), do: con[id]
  
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
  return a list of all ids in this expr
  """
  def ids({:const, _, _}), do: []
  def ids({:dup, sub, _}), do: ids(sub)
  def ids({:ext, sub, _, _, _}), do: ids(sub)
  def ids({:id, x}), do: [x]

  # unary operators
  def ids({:bit_not, sub}), do: ids(sub)
  def ids({:negate, sub}), do: ids(sub)
  def ids({:log_not, sub}), do: ids(sub)
  def ids({:bit_and, sub}), do: ids(sub)
  def ids({:bit_or, sub}), do: ids(sub)
  def ids({:bit_xor, sub}), do: ids(sub)

  # binary operators
  def ids({:add, l, r}), do: ids(l) ++ ids(r)
  def ids({:sub, l, r}), do: ids(l) ++ ids(r)
  def ids({:bit_and, l, r}), do: ids(l) ++ ids(r)
  def ids({:bit_or, l, r}), do: ids(l) ++ ids(r)
  def ids({:bit_xor, l, r}), do: ids(l) ++ ids(r)
  def ids({:equal, l, r}), do: ids(l) ++ ids(r)
  def ids({:greater, l, r}), do: ids(l) ++ ids(r)
  def ids({:less, l, r}), do: ids(l) ++ ids(r)
  def ids({:not_greater, l, r}), do: ids(l) ++ ids(r)
  def ids({:not_less, l, r}), do: ids(l) ++ ids(r)
  def ids({:unequal, l, r}), do: ids(l) ++ ids(r)
  def ids({:log_and, l, r}), do: ids(l) ++ ids(r)
  def ids({:log_or, l, r}), do: ids(l) ++ ids(r)
  def ids({:log_xor, l, r}), do: ids(l) ++ ids(r)
  def ids({:comma, l, r}), do: ids(l) ++ ids(r)

  # compound operators
  def ids({:bundle, items}), do: Enum.reduce(items, [], fn x, acc -> ids(x) ++ acc end) 
  def ids({:bundle_or, items}), do: Enum.reduce(items, [], fn x, acc -> ids(x) ++ acc end)
  def ids({:bundle_and, items}), do: Enum.reduce(items, [], fn x, acc -> ids(x) ++ acc end)
  def ids({:bundle_xor, items}), do: Enum.reduce(items, [], fn x, acc -> ids(x) ++ acc end)

  def ids({:choice, condition, choices}) do
    Enum.reduce(choices, ids(condition), fn x, acc -> ids(x) ++ acc end)
  end

  def ids({:ifs, conditions, choices}) do
    l = Enum.reduce(choices, [], fn x, acc -> ids(x) ++ acc end)
    Enum.reduce(conditions, l, fn x, acc -> ids(x) ++ acc end)
  end

  def ids({:cases, sub, cases, choices}) do
    l = Enum.reduce(choices, ids(sub), fn x, acc -> ids(x) ++ acc end)
    Enum.reduce(cases, l, fn x, acc -> ids(x) ++ acc end)
  end

  @doc """
  ast_string(ast, callback)
  return a string representation of ast. when encounter an id, use the callback for the string
  generation
  """
  def ast_string({:const, 0, v}, _), do: to_string(v)
  def ast_string({:const, w, v}, _), do: "#{w}'d#{v}"
  # FIXME
  def ast_string({:id, name}, f), do: f.(name)
  def ast_string({:dup, sub, times}, f), do: "{#{times}{#{ast_string(sub, f)}}}"
  def ast_string({:ext, sub, msb, lsb, -1}, f), do: "#{ast_string(sub, f)}[#{msb}:#{lsb}]"
  def ast_string({:ext, sub, msb, lsb, step}, f), do: "#{ast_string(sub, f)}[#{msb}:#{lsb}:#{step}]"
  
  # unary operators
  def ast_string({:bit_not, sub}, f), do: "(~ #{ast_string(sub, f)})"
  def ast_string({:negate, sub}, f), do: "(- #{ast_string(sub, f)})"
  def ast_string({:log_not, sub}, f), do: "(! #{ast_string(sub, f)})"
  def ast_string({:bit_and, sub}, f), do: "(& #{ast_string(sub, f)})"
  def ast_string({:bit_or, sub}, f), do: "(| #{ast_string(sub, f)})"
  def ast_string({:bit_xor, sub}, f), do: "(^ #{ast_string(sub, f)})"

  # binary operators
  def ast_string({:add, l, r}, f), do: "(#{ast_string(l, f)} + #{ast_string(r, f)})"
  def ast_string({:sub, l, r}, f), do: "(#{ast_string(l, f)} - #{ast_string(r, f)})"
  def ast_string({:bit_and, l, r}, f), do: "(#{ast_string(l, f)} & #{ast_string(r, f)})"
  def ast_string({:bit_or, l, r}, f), do: "(#{ast_string(l, f)} | #{ast_string(r, f)})"
  def ast_string({:bit_xor, l, r}, f), do: "(#{ast_string(l, f)} ^ #{ast_string(r, f)})"
  def ast_string({:equal, l, r}, f), do: "(#{ast_string(l, f)} == #{ast_string(r, f)})"
  def ast_string({:greater, l, r}, f), do: "(#{ast_string(l, f)} > #{ast_string(r, f)})"
  def ast_string({:less, l, r}, f), do: "(#{ast_string(l, f)} < #{ast_string(r, f)})"
  def ast_string({:not_greater, l, r}, f), do: "(#{ast_string(l, f)} <= #{ast_string(r, f)})"
  def ast_string({:not_less, l, r}, f), do: "(#{ast_string(l, f)} >= #{ast_string(r, f)})"
  def ast_string({:unequal, l, r}, f), do: "(#{ast_string(l, f)} != #{ast_string(r, f)})"
  def ast_string({:log_and, l, r}, f), do: "(#{ast_string(l, f)} && #{ast_string(r, f)})"
  def ast_string({:log_or, l, r}, f), do: "(#{ast_string(l, f)} || #{ast_string(r, f)})"
  def ast_string({:log_xor, l, r}, f), do: "(#{ast_string(l, f)} ^^ #{ast_string(r, f)})"
  def ast_string({:comma, l, r}, f), do: "{#{ast_string(l, f)}, #{ast_string(r, f)}}"

  # compound operators
  def ast_string({:bundle, items}, f), do: "{#{ast_string_bundle(",", items, f)}}"
  def ast_string({:bundle_or, items}, f), do: "(#{ast_string_bundle("|", items, f)})"
  def ast_string({:bundle_and, items}, f), do: "(#{ast_string_bundle("&", items, f)})"
  def ast_string({:bundle_xor, items}, f), do: "(#{ast_string_bundle("^", items, f)})"

  # FIXME: catch all
  def ast_string(t, _), do: inspect(t)

  defp ast_string_bundle(_, [], _), do: ""
  defp ast_string_bundle(_, [head], f), do: ast_string(head, f)
  defp ast_string_bundle(op, [head | tail], f) do
    ast_string(head, f) <> op <> ast_string_bundle(op, tail, f)
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
