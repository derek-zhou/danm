defmodule Danm.BlackBox do
  @moduledoc """
  A block box is a design entity from external, danm does not know the innard.
  """

  alias Danm.SimpleExpr
  
  defstruct name: nil,
    attrs: %{},
    ports: %{},
    params: %{}

  # simple accessors
  def set_name(b, n), do: %{b | name: n}
  def set_attr(b, n, to: v), do: %{b | attrs: Map.put(b.attrs, n, v)}
  def drop_attr(b, n), do: %{b | attrs: Map.pop(b.attrs, n)}
  def set_param(b, n, to: v), do: %{b | params: Map.put(b.params, n, v)}
  def drop_param(b, n), do: %{b | params: Map.pop(b.params, n)}
  def add_port(b, n, dir: dir, width: w), do: %{b | ports: Map.put(b.ports, n, {dir, w})}

  @doc """
  parse_verilog(path)
  parse a verilog module from the path, return the blackbox
  """
  def parse_verilog(path) do
    file = File.open!(path, [:read, :utf8])
    {_, box, _, _} = parse_module(file)
    File.close(file)
    box
  end
  
  # we pass along the parser state, a tuple of {state, box, line, buffer}
  defp parse_module(f) do
    {:init, %Danm.BlackBox{}, 1, get_line!(f)}
    |> parse_skip_spaces(f)
    |> parse_expect_string("module")
    |> parse_skip_spaces(f)
    |> parse_module_name()
    |> parse_skip_spaces(f)
    |> parse_expect_string("(")
    |> parse_skip_spaces(f)
    |> parse_port_list(f)
    |> parse_skip_spaces(f)
    |> parse_statements(f)
  end

  defp get_line!(f) do
    case IO.read(f, :line) do
      :eof -> raise "End of file reached unexpectly"
      {:error, reason} -> raise "read error: " <> reason
      data -> data
    end
  end
  
  defp parse_skip_spaces({state, box, line, buffer}, f) do
    case String.trim_leading(buffer) do
      "" -> parse_skip_spaces({state, box, line + 1, get_line!(f)}, f)
      "/*" <> buffer ->
	{state, box, line, buffer}
	|> parse_skip_in_comment(f)
	|> parse_skip_spaces(f)
      "//" <> _ -> parse_skip_spaces({state, box, line + 1, get_line!(f)}, f)
      buffer -> {state, box, line, buffer}
    end
  end

  defp parse_skip_in_comment({state, box, line, buffer}, f) do
    if state == :init and String.first(buffer) == "*" do
      {line, buffer, comment} = capture_doc({line, buffer}, f, inject: "")
      {state, set_attr(box, :comment, to: comment), line, buffer}
    else
      case String.split(buffer, "*/", parts: 2) do
	[_, second] -> {state, box, line, second}
	_ -> parse_skip_in_comment({state, box, line+1, get_line!(f)}, f)
      end
    end
  end

  defp capture_doc({line, buffer}, f, inject: c) do
    case String.split(buffer, "*/", parts: 2) do
      [first, second] -> {line, second, append_doc(first, to: c)}
      _ -> capture_doc({line+1, get_line!(f)}, f, inject: append_doc(buffer, to: c))
    end
  end

  defp append_doc(line, to: doc) do
    case Regex.run(~r/^\s?\*\s?(.*)$/, line) do
      [_, s] ->
	if doc == "", do: s, else: doc <> "\n" <> s
      _ -> doc
    end
  end
  
  defp parse_expect_string({state, box, line, buffer}, str) do
    {first, rest} = String.split_at(buffer, String.length(str))
    if first == str do
      {state, box, line, rest}
    else
      raise "Expecting: #{str}, got: #{buffer} at line no: #{line}"      
    end
  end

  defp parse_module_name({_, box, line, buffer}) do
    case Regex.run(~r/^(\w+)(.*)/, buffer) do
      [_, first, rest] -> {:after_name, set_name(box, first), line, rest}
      _ -> raise "Cannot find identifier in #{buffer} at line no: #{line}"
    end
  end

  defp parse_port_list({_, box, line, buffer}, f) do
    case buffer do
      ")" <> rest -> {:after_list, box, line, rest}
      _ ->
	# FIXME: ignore every port in the port list for now 
	{_, line, buffer} = parse_id_list({[], line, buffer}, f)
	parse_expect_string({:after_list, box, line, buffer}, ")")
    end
    |> parse_skip_spaces(f)
    |> parse_expect_string(";")
  end
  
  defp parse_id_list({list, line, buffer}, f) do
    case Regex.run(~r/^(\w+)(.*)/, buffer) do
      [_, first, rest] ->
	{_, _, line, buffer} = parse_skip_spaces({nil, nil, line, rest}, f)
	case buffer do
	  "," <> rest ->
	    {_, _, line, buffer} = parse_skip_spaces({nil, nil, line, rest}, f)
	    parse_id_list({[first | list], line, buffer}, f)
	  rest -> {[first | list], line, rest}
	end
      _ -> raise "Cannot find identifier in: #{buffer} at line no: #{line}"
    end
  end

  defp parse_statements({state, box, line, buffer}, f) do
    case parse_one_statement({state, box, line, buffer}, f) do
      {:error, box, line, buffer} -> {:done, box, line, buffer}
      {state, box, line, buffer} ->
	{state, box, line, buffer}
	|> parse_skip_spaces(f)
	|> parse_statements(f)
    end
  end

  defp parse_one_statement({state, box, line, buffer}, f) do
    case Regex.run(~r/^(\w+)(.*)/, buffer) do
      [_, first, rest] ->
	{state, box, line, buffer} = parse_skip_spaces({state, box, line, rest}, f)
	case first do
	  "parameter" -> parse_parameter({state, box, line, buffer})
	  "input" -> parse_port({state, box, line, buffer}, f, dir: :input)
	  "output" -> parse_port({state, box, line, buffer}, f, dir: :output)
	  "inout" -> parse_port({state, box, line, buffer}, f, dir: :inout)
	  _ -> {:error, box, line, buffer}
	end
      _ -> raise "Cannot find identifier in #{buffer} at line no: #{line}"
    end
  end

  defp parse_parameter({state, box, line, buffer}) do
    # parse identifer = expr;
    case Regex.run(~r/^(\w+)\s*=\s*(.*);(.*)$/U, buffer) do
      [_, id, exp, rest] -> {state, set_param(box, id, to: SimpleExpr.parse(exp)), line, rest}
      _ -> raise "Cannot find valid statement in: #{buffer} at line no: #{line}"
    end
  end

  defp parse_port({state, box, line, buffer}, f, dir: dir) do
    # parse [expr:0] identifer, identifier, ...;
    {w, buffer} =
      case Regex.run(~r/^\[(.*):0\](.*)$/U, buffer) do
	  [_, exp, rest ] -> {SimpleExpr.optimize(SimpleExpr.parse(exp <> "+1")), rest}
	_ -> {1, buffer}
      end
    {state, box, line, buffer} = parse_skip_spaces({state, box, line, buffer}, f)
    {list, line, buffer} = parse_id_list({[], line, buffer}, f)
    box = List.foldl(list, box, fn p, b -> add_port(b, p, dir: dir, width: w) end) 
    {state, box, line, buffer}
    |> parse_expect_string(";")
    |> parse_skip_spaces(f)
  end

end
