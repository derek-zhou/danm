defmodule Danm.Schematic do
  @moduledoc """
  A schematic is a design entity composed inside Danm.
  """

  @doc """
  A schematic is an extention of a black box.
  insts is a map of instances, keyed by instance name. Each instance is either a schematic or a
  blackbox. 
  wires is a map of wires, keyed by wire name. Each wire is a list of tuples of:
  {:pin, i_name, p_name}, where i_name/p_name is connected instance name and port name 
  """
  defstruct name: nil,
    comment: "",
    ports: %{},
    params: %{},
    insts: %{},
    wires: %{}

  # simple accessors
  def set_instance(s, n, to: i), do: %{s | insts: Map.put(s.insts, n, i)}
  def drop_instance(s, n), do: %{s | insts: Map.pop(s.insts, n)}
  def set_wire(s, n, conns: c), do: %{s | wires: Map.put(s.wires, n, c)}
  def drop_wire(s, n), do: %{s | wires: Map.pop(s.wires, n)}

end
