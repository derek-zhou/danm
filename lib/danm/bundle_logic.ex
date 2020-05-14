defmodule Danm.BundleLogic do
  @moduledoc """
  A bundle logic is a design entity with several combo logic expr combined.
  """

  alias Danm.Entity
  alias Danm.WireExpr

  @doc """
  A bundle logic is just a wrapper around a list of expr. output is a string
  inputs is a map of %{name => width}
  """
  defstruct [ :output, width: 0, exprs: [], op: :comma, inputs: %{} ]

  defimpl Entity do

    def elaborate(b) do
      new_width = Enum.reduce(b.exprs, 0, fn x, acc ->
	w = WireExpr.width(x, in: b.inputs)
	case b.op do
	  :comma -> acc + w
	  _ -> max(acc, w)
	end
      end)
      if new_width == b.width, do: b, else: %{b | width: new_width}
    end

    def doc_string(b) do
      case b.op do
	:comma -> "Concatenate several expressions together"
	op -> "Bundle several expression together with #{op}"
      end
    end
    
    def type_string(_), do: "bundle logic"
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
  create a bundle logic. all width assume to be 0 for now
  """
  def new(op, exprs, as: n) do
    map =
      exprs
      |> Enum.flat_map(fn x -> WireExpr.ids(x) end) 
      |> Enum.map(fn x -> {x, 0} end)
      |> Map.new()
    %__MODULE__{exprs: exprs, output: n, inputs: map, op: op}
  end

  @doc """
  a string representation of the exp
  """
  def expr_string(c, f) do
    {left, op, right} =
      case c.op do
	:comma -> {"{", " , ", "}"}
	:or -> {"(", " | ", ")"}
	:and -> {"(", " & ", ")"}
	:xor -> {"(", " ^ ", ")"}
      end
    str =
      c.exprs
      |> Enum.map(fn x -> WireExpr.ast_string(x, f) end)
      |> Enum.join(op)
    left <> str <> right
  end

end
