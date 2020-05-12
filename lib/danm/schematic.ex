defmodule Danm.Schematic do
  @moduledoc """
  A schematic is a design entity composed inside Danm.
  """

  alias Danm.Entity
  alias Danm.BlackBox
  alias Danm.Sink
  alias Danm.Library

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
  defstruct name: nil,
    src: "",
    ports: %{},
    params: %{},
    insts: %{},
    wires: %{},
    module: nil

  defimpl Entity do

    def elaborate(b), do: apply(b.module, :build, [b])

    def doc_string(b) do
      cond do
	function_exported?(b.module, :doc_string, 1) -> apply(b.module, :doc_string, [b])
	true -> "description forth coming"
      end
    end

    def type_string(b), do: "schematic: " <> b.name

    def sub_modules(b), do: b.insts |> Map.keys()
    def sub_module_at(b, name), do: b.insts[name]
    def ports(b), do: b.ports |> Map.keys()
    def port_at(b, name), do: b.ports[name]

  end

  # simple accessors
  defp set_instance(s, n, to: i), do: %{s | insts: Map.put(s.insts, n, i)}
  defp set_wire(s, n, conns: c), do: %{s | wires: Map.put(s.wires, n, c)}
  defp merge_wire(s, n, conns: c), do: %{s | wires: Map.put(s.wires, n, c ++ s.wires[n])}

  @doc ~S"""
  add a sub module instance.
  optional arguments:

    * :as, instance name. if nil, a name as u_MODULE_NAME is used
    * :parameters, a map of additional parameters to set before elaborate

  """
  def add(s, name, options \\ []) do
    i_name = options[:as] || "u_#{name}"
    cond do
      Map.has_key?(s.insts, i_name) -> raise "Instance by the name of #{i_name} already exists"
      true ->
	m = Library.load_and_build_module(name, options[:parameters] || %{})
	set_instance(s, i_name, to: m)
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
	|> set_wire(name, conns: [{:self, name}])
    end
  end

  @doc ~S"""
  connect pins together as a wire
  optional arguments

    * :as, wire name. if nil, a name as the first port name is used

  """
  def connect(s, conns, options \\ []) do
    conns = Enum.map(conns, fn each ->
      case each do
	{inst, port} -> {inst, port}
	pin ->
	  pin
	  |> String.split("/", parts: 2)
	  |> List.to_tuple()
      end
    end)
    name = options[:as] || elem(hd(conns), 1)
    cond do
      Map.has_key?(s.wires, name) -> merge_wire(s, name, conns: conns)
      true -> set_wire(s, name, conns: conns)
    end
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
  sink a wire, so it has a fake load and not to be auto-exposed
  """
  def sink(s, l) when is_list(l), do: Enum.reduce(l, s, fn x, s -> sink(s, x) end)
  def sink(s, name) when is_binary(name) do
    unless Map.has_key?(s.wires, name), do: raise "Wire by the name of #{name} is not found"
    w = width_of_conns(s, s.wires[name])
    sink = case s.insts["_sink"] do
	     nil -> Sink.new_sink(name, w)
	     sink -> Sink.set_port(sink, name, w)
	   end
    s
    |> merge_wire(name, conns: [{"_sink", name}])
    |> set_instance("_sink", to: sink)
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
    Enum.reduce(s.wires[name], {0, 0, 1},
      fn {ins, port}, {drivers, loads, width} ->
	{dir, w} = case ins do
		     :self -> inverse_port(s.ports[port])
		     _ -> s |> Entity.sub_module_at(ins) |> Entity.port_at(port)
		   end
	{drivers + driver_count(dir), loads + load_count(dir), max(w, width)}
      end)
  end

  @doc ~S"""
  produce a map of w_name -> width for the design
  """
  def wire_width_map(s) do
    Map.new(s.wires, fn {w_name, conns} -> {w_name, width_of_conns(s, conns)} end)
  end

  defp width_of_conns(s, conns) do
    Enum.reduce_while(conns, 1, fn {ins, port}, width ->
      case ins do
	:self -> {:halt, elem(s.ports[port], 1)}
	_ -> {:cont, max(width, elem(s |> Entity.sub_module_at(ins) |> Entity.port_at(port), 1))}
      end
    end)
  end

  defp force_expose(s, name, dir: dir, width: width) do
    s
    |> BlackBox.set_port(name, dir: dir, width: width)
    |> merge_wire(name, conns: [{:self, name}])
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
      Map.has_key?(s.wires, name) -> merge_wire(s, name, conns: pins)
      true -> set_wire(s, name, conns: pins)
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

  defp inverse_port({dir, w}) do
   case dir do
      :input -> {:output, w}
      :output -> {:input, w}
      :inout -> {:inout, w}
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

end
