defmodule Danm.ConditionLogic do
  @moduledoc """
  A condition logic is a design entity with a list of conditions anf choices,
  output the choices when first condition evaluate to true
  """

  alias Danm.Entity
  alias Danm.WireExpr

  @doc """
  A condition logic is just a wrapper around a list of expr. output is a string
  inputs is a map of %{name => width}
  """
  defstruct [ :output, width: 0, conditions: [], choices: [], inputs: %{} ]

  defimpl Entity do

    def elaborate(b) do
      new_width = Enum.reduce(b.choices, 0, fn x, acc ->
	x |> WireExpr.width(in: b.inputs) |> max(acc)
      end)
      if new_width == b.width, do: b, else: %{b | width: new_width}
    end

    def name(b), do: b.output
    def doc_string(_), do: "Priority decoder"
    def type_string(_), do: "priority decoder"
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
  create a condition logic. all width assume to be 0 for now
  """
  def new(conditions, choices, as: n) do
    map =
      (conditions ++ choices)
      |> Enum.flat_map(fn x -> WireExpr.ids(x) end)
      |> Map.new(fn x -> {x, 0} end)
    %__MODULE__{conditions: conditions, choices: choices, output: n, inputs: map}
  end

  @doc """
  check the last condition to see if it is true
  """
  def last_is_true?(s) do
    case Enum.at(s.conditions, -1) do
      {:const, _, v} -> v > 0
      _ -> false
    end
  end

end
