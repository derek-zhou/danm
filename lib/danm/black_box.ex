defmodule Danm.BlackBox do
  @moduledoc """
  A block box is a design entity from external, danm does not know the innard.
  """

  alias Danm.SimpleExpr
  
  defstruct name: nil,
    comment: "",
    src: "",
    ports: %{},
    params: %{}

  # simple accessors
  def set_name(b, n), do: %{b | name: n}
  def set_comment(b, n), do: %{b | comment: n}
  def set_parameter(b, n, to: v), do: %{b | params: Map.put(b.params, n, v)}
  def drop_parameter(b, n), do: %{b | params: Map.pop(b.params, n)}
  def merge_parameters(b, d), do: %{b | params: Map.merge(b.params, d)}
  def set_port(b, n, dir: dir, width: w), do: %{b | ports: Map.put(b.ports, n, {dir, w})}
  def drop_port(b, n), do: %{b | ports: Map.pop(b.ports, n)}

  @doc """
  resolve
  resolve parameters and port width to their value
  """
  def resolve(b) do
    b
    |> resolve_parameter()
    |> resolve_port_width()
  end

  @doc """
  whether the box is fully resolved, ie. all parameter and port width are integers
  """
  def resolved?(b) do
    Enum.reduce(b.params, true, fn {_, v}, a ->
      a and is_integer(v) end) and
    Enum.reduce(b.ports, true, fn {_, {_, w}}, a ->
      a and is_integer(w) end)
  end
  
  defp eval_expr(e, in: dict) do
    case e do
      n when is_integer(n) -> {n, 0}
      e -> case SimpleExpr.eval(e, in: dict) do
	     n when is_integer(n) -> {n, 1}
	     e -> {e, 0}
	   end
    end
  end
  
  defp resolve_parameter(b) do
    {map, sum} = Enum.reduce(b.params, {%{}, 0}, fn {k, v}, {map, sum} ->
      {v, x} = eval_expr(v, in: b.params) 
      {Map.put(map, k, v), sum + x}
    end)
    b = %{b | params: map}
    if sum > 0, do: resolve_parameter(b), else: b
  end

  defp resolve_port_width(b) do
    {map, sum} = Enum.reduce(b.ports, {%{}, 0}, fn {k, {dir, w}}, {map, sum} ->
      {w, x} = eval_expr(w, in: b.params) 
      {Map.put(map, k, {dir, w}), sum + x}
    end)
    b = %{b | ports: map}
    if sum > 0, do: resolve_port_width(b), else: b
  end    
      
  @doc """
  parse_verilog(path)
  parse a verilog module from the path, return the blackbox
  """
  def parse_verilog(path) do
    case File.open(path, [:read, :utf8]) do
      {:ok, file} ->
	box = %Danm.BlackBox{src: path}
	{_, box, _, _} = parse_module(box, file)
	File.close(file)
	box
      {:error, _} -> nil
    end
  end
  
  # we pass along the parser state, a tuple of {state, box, line, buffer}
  defp parse_module(box, f) do
    {:init, box, 1, get_line!(f)}
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
      {state, set_comment(box, comment), line, buffer}
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
      [_, id, exp, rest] -> {state, set_parameter(box, id, to: SimpleExpr.parse(exp)), line, rest}
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
    box = List.foldl(list, box, fn p, b -> set_port(b, p, dir: dir, width: w) end) 
    {state, box, line, buffer}
    |> parse_expect_string(";")
    |> parse_skip_spaces(f)
  end

end
