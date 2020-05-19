defmodule Danm.Assertion do
  @moduledoc """
  An assertion is a design entity with some input ports that combined to a one bit value
  and cannot be 1
  """

  alias Danm.Entity
  alias Danm.WireExpr

  @doc """
  asseriton wrap around an expression, optionally has a clock
  """
  defstruct [:expr, :clk, inputs: %{}, silent_time: 100]

  defimpl Entity do

    def elaborate(b), do: b
    def name(_), do: "_assertion"
    def type_string(_), do: "assertion"

    def ports(b) do
      case b.clk do
	nil -> Map.keys(b.inputs)
	clk -> [clk | Map.keys(b.inputs)]
      end
    end

    def port_at(b, name) do
      cond do
	name == b.clk -> {:input, 1}
	b.inputs[name] -> {:input, b.inputs[name]}
	true -> nil
      end
    end

  end

  @doc """
  create an asserion. all width assume to be 0 for now
  """
  def new(str, clk) do
    expr = WireExpr.parse(str)
    map = expr |> WireExpr.ids() |> Map.new(fn x -> {x, 0} end)
    %__MODULE__{expr: expr, clk: clk, inputs: map}
  end

end
