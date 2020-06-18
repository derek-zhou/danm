defmodule Danm.Assertion do
  @moduledoc false

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

    def port_at!(b, name) do
      cond do
	name == b.clk -> {:input, 1}
	true -> {:input, Map.fetch!(b.inputs, name)}
      end
    end

    def has_port?(b, name) do
      cond do
	name == b.clk -> true
	true -> Map.has_key?(b.inputs, name)
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
