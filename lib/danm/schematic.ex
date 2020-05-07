defmodule Danm.Schematic do
  @moduledoc """
  A schematic is a design entity composed inside Danm.
  """

  alias Danm.BlackBox
  alias Danm.Library

  @doc """
  A schematic is an extention of a black box.
  insts is a map of instances, keyed by instance name. Each instance is either a schematic or a
  blackbox. 
  wires is a map of wires, keyed by wire name. Each wire is a list of tuples of:
  {i_name, p_name}, where i_name/p_name is connected instance name and port name
  module is the elixir module that it is defined in
  """
  defstruct name: nil,
    ports: %{},
    params: %{},
    insts: %{},
    wires: %{},
    module: nil

  # simple accessors
  def set_instance(s, n, to: i), do: %{s | insts: Map.put(s.insts, n, i)}
  def drop_instance(s, n), do: %{s | insts: Map.pop(s.insts, n)}
  def set_wire(s, n, conns: c), do: %{s | wires: Map.put(s.wires, n, c)}
  def drop_wire(s, n), do: %{s | wires: Map.pop(s.wires, n)}
  def merge_wire(s, n, conns: c), do: %{s | wires: Map.put(s.wires, n, c ++ s.wires[n])}

  @doc """
  elaborate the design. This will call the schematic suplied build fuction, which will 
  call elaborate for all sub modules
  """
  def elaborate(s) do
    case s.__struct__ do
      Danm.BlackBox -> BlackBox.resolve(s)
      Danm.Schematic -> Function.capture(s.module, :build, 1).(s)
    end
  end

  @doc ~S"""
  add a sub module instance.
  optional arguments:

    * :as, instance name. if nil, a name as u_MODULE_NAME is used
    * :parameters, a map of additional parameters to set before elaborate

  """
  def add_instance_of(s, name, options \\ []) do
    m = name
    |> Library.load_module()
    |> BlackBox.merge_parameters(options[:parameters] || %{})
    |> elaborate()

    i_name = options[:as] || "u_#{name}"
    if Map.has_key?(s.insts, i_name) do
      raise "Instance by the name of #{i_name} already exists"
    else
      set_instance(s, i_name, to: m)
    end
  end

  @doc ~S"""
  create an input port
  optional arguments

    * :width, the width. default is 1

  """
  def create_port(s, name, options \\ []) do
    if Map.has_key?(s.wires, name) do
      raise "Port by the name of #{name} already exists"
    else
      s
      |> BlackBox.set_port(name, dir: :input, width: options[:width] || 1)
      |> set_wire(name, conns: [:input])
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
    if Map.has_key?(s.wires, name) do
      merge_wire(s, name, conns: conns)
    else
      set_wire(s, name, conns: conns)
    end
  end

  @doc ~S"""
  expose the wire as a port. width and direction are automatically figured out
  """
  def expose(s, name) do
    if Map.has_key?(s.wires, name) do
      unless Map.has_key?(s.ports, name) do
	{drivers, _, width} = inspect_wire(s, name)
	dir = if drivers > 0, do: :output, else: :input
	force_expose(s, name, dir: dir, width: width)
      end
    else
      raise "Wire by the name of #{name} is not found"
    end
  end

  @doc ~S"""
  expose every wire that is either not loaded or driven.
  """
  def auto_expose(s), do: Enum.reduce(s.wires, s, fn {n, _}, s -> auto_expose(s, n) end)

  @doc ~S"""
  expose one wire if necessary
  """
  def auto_expose(s, name) do
    if Map.has_key?(s.ports, name) do
      s
    else
      {drivers, loads, width} = inspect_wire(s, name)
      cond do
	drivers > 0 and loads == 0 -> force_expose(s, name, dir: :output, width: width)
	drivers == 0 and loads > 0 -> force_expose(s, name, dir: :input, width: width)
	true -> s
      end
    end
  end

  defp inspect_wire(s, name) do
    Enum.reduce(s.wires[name], {0, 0, 1},
      fn {ins, port}, {drivers, loads, width} ->
	case s.insts[ins].ports[port] do
	  {dir, n} ->
	    {drivers + driver_count(dir),
	     loads + load_count(dir),
	     max(n, width)}
	end
      end)
  end

  defp force_expose(s, name, dir: dir, width: width) do
    s
    |> BlackBox.set_port(name, dir: dir, width: width)
    |> merge_wire(name, conns: [dir])
  end

  @doc ~S"""
  connect all pins in the design by name.
  Only connect conservatively, so all connected pins are same width, 0 or 1 driver
  """
  def auto_connect(s) do
    # set of unique port name
    set = Enum.reduce(s.insts, MapSet.new(), fn {_, inst}, set ->
      MapSet.union(set, Enum.reduce(inst.ports, MapSet.new(), fn {p_name, _}, set ->
	    MapSet.put(set, p_name)
	  end))
    end)
    # map of pin -> w_name
    map = Enum.reduce(s.wires, %{}, fn {w_name, conns}, map ->
      Map.merge(map, Enum.reduce(conns, %{}, fn each, map ->
	    case each do
	      {ins, port} -> Map.put(map, "#{ins}/#{port}", w_name)
	      _ -> map
	    end
	  end))
    end)
    # do auto connect for each unique port name, with pin -> w_name map as an aid
    Enum.reduce(set, s, fn p_name, s -> auto_connect(s, p_name, map) end)
  end

  defp auto_connect(s, name, pw_map) do
    {drivers, _, width} = if Map.has_key?(s.wires, name) do
      inspect_wire(s, name)
    else
      {0, 0, 0}
    end
    # in the following loop, i try to find out all pins with this name and not connected,
    # driver count, width. I set width to -1 if width does not matcch 
    {drivers, width, pins} = Enum.reduce(s.insts, {drivers, width, []},
      fn {i_name, inst}, {drivers, width, list} ->
	if Map.has_key?(pw_map, "#{i_name}/#{name}") do
	  # already connected, skip
	  {drivers, width, list}
	else
	  case inst.ports[name] do
	    nil -> {drivers, width, list}
	    {dir, w} ->
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
