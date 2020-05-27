defmodule Danm.ComboLogic do
  @moduledoc """
  A combo logic is a design entity with some input ports and one output, and the output
  is derived from input as a combinatorial logic expression
  """

  alias Danm.Entity
  alias Danm.WireExpr
  alias Danm.ComboLogic

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

    def name(b), do: b.output
    def type_string(_), do: "combo logic"
    def ports(b), do: ComboLogic.ports(b)
    def port_at!(b, name), do: ComboLogic.port_at!(b, name)
    def has_port?(b, name), do: ComboLogic.has_port?(b, name)

  end

  @doc """
  create a combo logic. all width assume to be 0 for now
  """
  def new(str, as: n) do
    expr = WireExpr.parse(str)
    map = expr |> WireExpr.ids() |> Map.new(fn x -> {x, 0} end)
    %__MODULE__{expr: expr, output: n, inputs: map}
  end

  @doc """
  whether output is part of inputs
  """
  def loop_back?(b), do: Map.has_key?(b.inputs, b.output)

  @doc """
  my ports function
  """
  def ports(b) do
    cond do
      loop_back?(b) -> Map.keys(b.inputs)
      true -> [ b.output | Map.keys(b.inputs) ]
    end
  end

  @doc """
  my port_at function
  """
  def port_at!(b, name) do
    cond do
      name == b.output -> {:output, b.width}
      true -> {:input, Map.fetch!(b.inputs, name)}
    end
  end

  @doc """
  my has_port function
  """
  def has_port?(b, name) do
    cond do
      name == b.output -> true
      true -> Map.has_key?(b.inputs, name)
    end
  end

end
