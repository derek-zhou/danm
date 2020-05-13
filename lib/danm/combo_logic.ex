defmodule Danm.ComboLogic do
  @moduledoc """
  A combo logic is a design entity with some input ports and one output, and the output
  is derived from input as a combinatorial logic expression
  """

  alias Danm.Entity
  alias Danm.WireExpr

  @doc """
  A combo logic is just a wrapper around an expr. output is a string
  inputs is a map of %{name => width}
  """
  defstruct [ :expr, :output, width: 0, inputs: %{} ]

  defimpl Entity do

    def elaborate(b) do
      new_width = WireExpr.width(b.expr, in: b.inputs)
      if new_width == b.width, do: b, else: %{b | width: new_width}
    end

    def doc_string(_), do: "Just a combo logic"
    def type_string(_), do: "combo logic"
    def sub_modules(_), do: []
    def sub_module_at(_, _), do: nil
    def ports(b), do: [ b.output | Map.keys(b.inputs) ]

    def port_at(b, name) do
      cond do
	name == b.output -> {:output, b.width}
	Map.has_key?(b.inputs, name) -> {:input, b.inputs[name]}
	true -> nil
      end
    end

  end

  @doc """
  create a combo logic. all width assume to be 0 for now
  """
  def new(exp, as: n) do
    map = exp |> WireExpr.ids() |> Enum.map(fn x -> {x, 0} end) |> Map.new()
    %__MODULE__{expr: exp, output: n, inputs: map}
  end

  @doc """
  a string representation of the exp
  """
  def exp_string(c, f), do: WireExpr.ast_string(c.expr, f)

end
