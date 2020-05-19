defmodule Danm.Schematic.CollisionDetector do

  use Bitwise
  import Danm.Schematic

  def doc_string(_) do
    ~S"""
    I detect and assert that no 2 bits from inputs are one at the same time
    """
  end

  def build(s) do
    width = s.params["width"] || 8
    s
    |> create_port("clk")
    |> create_port("in", width: width)
    |> bind_to(s)

    collision = Enum.flat_map(0..width - 2, fn i ->
      Enum.map(i+1..width - 1, fn j -> "collision_#{i}_#{j}" end)
    end)
    Enum.reduce(0..width - 2, s, fn i, s ->
      Enum.reduce(i+1..width - 1, s, fn j, s ->
	assign(s, "in[#{i}]&in[#{j}]", as: "collision_#{i}_#{j}")
      end)
    end)
    |> bundle(collision, as: "collision")
    |> forbid("|collision", flop_by: "clk")
  end

end
