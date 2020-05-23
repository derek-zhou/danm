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
    collision = Enum.flat_map(0..width - 2, fn i ->
      Enum.map(i+1..width - 1, fn j -> "collision_#{i}_#{j}" end)
    end)
    s
    |> create_port("clk")
    |> create_port("in", width: width)
    |> roll_in(0..width - 2, fn i, s ->
         Enum.reduce(i+1..width - 1, s, fn j, s ->
	   assign(s, "in[#{i}]&in[#{j}]", as: "collision_#{i}_#{j}")
	 end)
       end)
    |> bundle(collision, as: "collision")
    |> die_when("|collision", flop_by: "clk")
  end

end
