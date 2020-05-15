defmodule Danm.Schematic do
  @moduledoc """
  A schematic is a design entity composed inside Danm.
  """

  alias Danm.Entity
  alias Danm.BlackBox
  alias Danm.Schematic
  alias Danm.Sink
  alias Danm.ComboLogic
  alias Danm.BundleLogic
  alias Danm.ChoiceLogic
  alias Danm.ConditionLogic
  alias Danm.CaseLogic
  alias Danm.Library
  alias Danm.WireExpr

  @doc """
  A schematic is an extention of a black box.
  insts is a map of instances, keyed by instance name. Each instance is either a schematic or a
  blackbox. 
  wires is a map of wires, keyed by wire name. Each wire is a list of tuples of:
  {i_name, p_name}, where i_name/p_name is connected instance name and port name
  in the case of a wire is also connected to a port, the i_name is :self, p_name has to be
  the same as the wire name in this case
  for wire as expression the tuple is {:expr, expr}
  module is the elixir module that it is defined in
  """
  defstruct [
    :name,
    :module,
    src: "",
    ports: %{},
    params: %{},
    insts: %{},
    wires: %{},
  ]

  defimpl Entity do

    def elaborate(b) do
      b.module
      |> apply(:build, [b])
      |> resolve_logic()
      |> resolve_port_width()
    end

    def name(b), do: b.name

    def doc_string(b) do
      cond do
	function_exported?(b.module, :doc_string, 1) -> apply(b.module, :doc_string, [b])
	true -> "description forth coming"
      end
    end

    def type_string(b), do: "schematic: " <> b.name

    def ports(b), do: b.ports |> Map.keys()
    def port_at(b, name), do: b.ports[name]

    defp resolve_logic(b) do
      {map, changes} = Enum.reduce(b.insts, {%{}, 0}, fn {i_name, inst}, {map, changes} ->
	case inst.__struct__ do
	  t when t in [BlackBox, Schematic] -> {Map.put(map, i_name, inst), changes}
	  _ ->
	    inst_new = inst |> resolve_inputs(in: b) |> Entity.elaborate()
	    cond do
	      inst_new === inst -> {Map.put(map, i_name, inst), changes}
	      true -> {Map.put(map, i_name, inst_new), changes + 1}
	    end
	end
      end)
      b = %{b | insts: map}
      if changes > 0, do: resolve_logic(b), else: b
    end

    defp resolve_inputs(inst, in: s) do
      inst.inputs
      |> Enum.reduce(inst, fn {p_name, w}, inst ->
	w_new = Schematic.width_of_wire(s, s.wires[p_name])
	cond do
	  w_new == w -> inst
	  true -> Sink.set_input(inst, p_name, w_new)
	end
      end)
    end

    defp resolve_port_width(b) do
      new_ports = Enum.reduce(b.ports, %{}, fn {p_name, {dir, _}}, map ->
	Map.put(map, p_name, {dir, Schematic.width_of_wire(b, b.wires[p_name])})
      end)
      %{b | ports: new_ports}
    end

  end

  # simple accessors
  defp set_instance(s, n, to: i), do: %{s | insts: Map.put(s.insts, n, i)}
  defp set_wire(s, n, c), do: %{s | wires: Map.put(s.wires, n, [c])}
  defp merge_wire(s, n, c), do: %{s | wires: Map.put(s.wires, n, [ c | s.wires[n] ])}

  defp conjure_wire(s, n, conns: c) do
    list = cond do
      Map.has_key?(s.wires, n) -> s.wires[n]
      true -> []
    end
    # make sure conns are valid
    list = Enum.reduce(c, list, fn {inst, port}, list ->
      case inst do
	:self ->
	  if s.ports[port] == nil do
	    raise "Port of name #{port} is not found in design #{s.name}"
	  end
	_ ->
	  case s.insts[inst] do
	    nil -> raise "Instance of name #{inst} is not found in design #{s.name}"
	    i ->
	      if Entity.port_at(i, port) == nil do
		raise "Port of name #{port} is not found in design #{i.name}"
	      end
	  end
      end
      [ {inst, port} | list ]
    end)
    %{s | wires: Map.put(s.wires, n, list)}
  end

  @doc ~S"""
  add a sub module instance.
  optional arguments:

    * :as, instance name. if nil, a name as u_MODULE_NAME is used
    * :parameters, a map of additional parameters to set before elaborate
    * :connections, a map of port to wire name for connection

  """
  def add(s, name, options \\ []) do
    i_name = options[:as] || "u_#{name}"
    s =
      case s.insts[i_name] do
        nil ->
	  m = Library.load_and_build_module(name, options[:parameters] || %{})
	  set_instance(s, i_name, to: m)
	_ -> raise "Instance by the name of #{i_name} already exists"
      end
    case options[:connections] do
      nil -> s
      cs ->
	Enum.reduce(cs, s, fn {p_name, w_name}, s ->
	  conjure_wire(s, w_name, conns: [{i_name, p_name}])
	end)
    end
  end

  @doc ~S"""
  create an input port
  optional arguments

    * :width, the width. default is 1

  """
  def create_port(s, name, options \\ []) do
    cond do
      Map.has_key?(s.wires, name) -> raise "Wire by the name of #{name} already exists"
      true -> 
	s
	|> BlackBox.set_port(name, dir: :input, width: options[:width] || 1)
	|> set_wire(name, {:self, name})
    end
  end

  @doc ~S"""
  connect pins together as a wire
  optional arguments

    * :as, wire name. if nil, a name as the first port name is used

  """
  def connect(s, conns, options \\ [])
  def connect(s, str, options) when is_binary(str), do: connect(s, [str], options) 
  def connect(s, conns, options) when is_list(conns) do
    conns = Enum.map(conns, fn each ->
      case each do
	{inst, port} -> {inst, port}
	pin -> pin |> String.split("/", parts: 2) |> List.to_tuple()
      end
    end)
    conjure_wire(s, options[:as] || elem(hd(conns), 1), conns: conns)
  end

  @doc ~S"""
  expose the wire as a port. width and direction are automatically figured out
  """
  def expose(s, l) when is_list(l), do: Enum.reduce(l, s, fn x, s -> expose(s, x) end)
  def expose(s, name) when is_binary(name) do
    unless Map.has_key?(s.wires, name), do: raise "Wire by the name of #{name} is not found"
    {drivers, _, width} = inspect_wire(s, name)
    dir = if drivers > 0, do: :output, else: :input
    cond do
      Map.has_key?(s.ports, name) -> s
      true -> force_expose(s, name, dir: dir, width: width)
    end
  end

  @doc ~S"""
  expose every wire that is either not loaded or driven.
  """
  def auto_expose(s), do: Enum.reduce(s.wires, s, fn {n, _}, s -> auto_expose(s, n) end)

  defp auto_expose(s, name) do
    {drivers, loads, width} = inspect_wire(s, name)
    cond do
      Map.has_key?(s.ports, name) -> s
      drivers > 0 and loads == 0 -> force_expose(s, name, dir: :output, width: width)
      drivers == 0 and loads > 0 -> force_expose(s, name, dir: :input, width: width)
      true -> s
    end
  end

  @doc ~S"""
  return driver count, load count and calculated width
  """
  def inspect_wire(s, name) do
    Enum.reduce(s.wires[name], {0, 0, 0},
      fn {ins, port}, {drivers, loads, width} ->
	{dir, w} = pin_property(s, ins, port)
	dc = driver_count(dir)
	{drivers + dc,
	 loads + load_count(dir),
	 (if dc > 0, do: w, else: max(width, w))}
      end)
  end

  @doc ~S"""
  produce a map of w_name -> width for the design
  """
  def wire_width_map(s) do
    Map.new(s.wires, fn {w_name, conns} -> {w_name, width_of_wire(s, conns)} end)
  end

  @doc ~S"""
  return the width of a wire. First driver rules, failing that, the widest load
  """
  def width_of_wire(s, conns) do
    Enum.reduce_while(conns, 0, fn {ins, port}, width ->
      {dir, w} = pin_property(s, ins, port)
      case driver_count(dir) do
	0 -> {:cont, max(width, w)}
	_ -> {:halt, w}
      end
    end)
  end

  @doc ~S"""
  return the driver of wire as a conn tuple.
  """
  def driver_of_wire(s, conns) do
    Enum.find(conns, fn {ins, port} ->
      {dir, _} = pin_property(s, ins, port)
      driver_count(dir) > 0
    end)
  end

  defp force_expose(s, name, dir: dir, width: width) do
    s
    |> BlackBox.set_port(name, dir: dir, width: width)
    |> merge_wire(name, {:self, name})
  end

  @doc ~S"""
  connect all pins in the design by name.
  Only connect conservatively, so all connected pins are same width, 0 or 1 driver
  """
  def auto_connect(s) do
    # set of unique port name
    set = Enum.reduce(s.insts, MapSet.new(), fn {_, inst}, set ->
      inst |> Entity.ports() |> MapSet.new() |> MapSet.union(set)
    end)
    map = pin_to_wire_map(s)
    # do auto connect for each unique port name, with pin -> w_name map as an aid
    Enum.reduce(set, s, fn p_name, s -> auto_connect(s, p_name, map) end)
  end

  @doc ~S"""
  produce a map of pin -> w_name for the design
  """
  def pin_to_wire_map(s) do
    Enum.reduce(s.wires, %{}, fn {w_name, conns}, map ->
      conns
      |> Enum.map(fn {ins, port} -> {"#{ins}/#{port}", w_name} end)
      |> Map.new()
      |> Map.merge(map)
    end)
  end

  defp auto_connect(s, name, pw_map) do
    {drivers, _, width} = case Map.has_key?(s.wires, name) do
			    true -> inspect_wire(s, name)
			    false -> {0, 0, 0}
			  end
    # in the following loop, i try to find out all pins with this name and not connected,
    # driver count, width. I set width to -1 if width does not matcch 
    {drivers, width, pins} = Enum.reduce(s.insts, {drivers, width, []},
      fn {i_name, inst}, {drivers, width, list} ->
	case Entity.port_at(inst, name) do
	  nil -> {drivers, width, list}
	  {dir, w} ->
	    cond do
	      Map.has_key?(pw_map, "#{i_name}/#{name}") -> {drivers, width, list}
	      true ->
		{drivers + driver_count(dir),
		 common_width(width, w),
		 [ {i_name, name} | list ]}
	    end
	end
      end)
    cond do
      drivers > 1 -> s
      width < 0 -> s
      pins == [] -> s
      true -> conjure_wire(s, name, conns: pins)
    end
  end

  # return w2 or -1
  defp common_width(w1, w2) do
    cond do
      w1 == 0 -> w2
      w1 == w2 -> w2
      true -> -1
    end
  end

  defp inverse_dir(dir) do
   case dir do
      :input -> :output
      :output -> :input
      :inout -> :inout
    end
  end

  defp pin_property(s, i_name, p_name) do
    case i_name do
      :self ->
	{dir, w} = Entity.port_at(s, p_name)
	{inverse_dir(dir), w}
      _ -> Entity.port_at(s.insts[i_name], p_name)
    end
  end

  defp driver_count(dir) do
    case dir do
      :input -> 0
      :output -> 1
      :inout -> 1
    end
  end

  defp load_count(dir) do
    case dir do
      :input -> 1
      :output -> 0
      :inout -> 1
    end
  end

  defp inst_order_of(i, s) do
    order_map = %{
      BlackBox => 0,
      Schematic => 1,
      ComboLogic => 2,
      BundleLogic => 3,
      ChoiceLogic => 4,
      ConditionLogic => 5,
      CaseLogic => 6,
      Sink => 9
    }
    Map.fetch!(order_map, s.insts[i].__struct__)
  end

  defp compare_inst(oa, a, ob, b) do
    cond do
      oa < ob -> true
      oa > ob -> false
      true -> a <= b
    end
  end

  @doc ~S"""
  return a sorted list of instances
  """
  def sort_sub_modules(s) do
    s.insts
    |> Map.keys()
    |> Enum.sort(fn a, b -> compare_inst(inst_order_of(a, s), a, inst_order_of(b, s), b) end)
  end

  @doc ~S"""
  sink a wire, so it has a fake load and not to be auto-exposed
  """
  def sink(s, name) when is_binary(name), do: sink(s, [name])
  def sink(s, l) when is_list(l) do
    sink =
      case s.insts["_sink"] do
	nil -> Sink.new(l)
	sink -> Sink.merge(sink, l)
      end
    s |> set_instance("_sink", to: sink) |> connect_wires(sink, "_sink")
  end

  @doc ~S"""
  assign an expression to a wire
  """
  def assign(s, str, as: n) do
    cl = str |> WireExpr.parse() |> ComboLogic.new(as: n)
    s |> set_instance(n, to: cl) |> connect_wires(cl, n)
  end

  @doc ~S"""
  bundle expressions to a wire with given op
  """
  def bundle(s, strs, as: n), do: bundle(s, strs, with: :comma, as: n)
  def bundle(s, strs, with: op, as: n) do
    exprs = Enum.map(strs, fn str -> WireExpr.parse(str) end)
    bl = BundleLogic.new(op, exprs, as: n)
    s |> set_instance(n, to: bl) |> connect_wires(bl, n)
  end

  defp connect_wires(s, inst, n) do
    inst
    |> Entity.ports()
    |> Enum.reduce(s, fn p_name, s -> conjure_wire(s, p_name, conns: [{n, p_name}]) end)
  end

  @doc ~S"""
  pick one choice out of 2^n choices based on condition value
  """
  def decode(s, condition, choices, as: n) do
    condition = WireExpr.parse(condition)
    choices = Enum.map(choices, fn str -> WireExpr.parse(str) end)
    cl = ChoiceLogic.new(condition, choices, as: n)
    s |> set_instance(n, to: cl) |> connect_wires(cl, n)   
  end

  @doc ~S"""
  pick one choice out of n choices based on first none zero condition.
  the list is a list of {condition, choice} tuple
  """
  def condition(s, list, as: n) do
    conditions = Enum.map(list, fn {str, _} -> WireExpr.parse(str) end)
    choices = Enum.map(list, fn {_, str} -> WireExpr.parse(str) end)
    cl = ConditionLogic.new(conditions, choices, as: n)
    s |> set_instance(n, to: cl) |> connect_wires(cl, n)    
  end

  @doc ~S"""
  pick one choice out of n choices based on subject matching condition.
  the list is a list of {condition, choice} tuple
  """
  def case(s, subject, list, as: n) do
    subject = WireExpr.parse(subject)
    conditions = Enum.map(list, fn {str, _} -> WireExpr.parse(str) end)
    choices = Enum.map(list, fn {_, str} -> WireExpr.parse(str) end)
    cl = CaseLogic.new(subject, conditions, choices, as: n)
    s |> set_instance(n, to: cl) |> connect_wires(cl, n)    
  end

end
