defmodule Danm.ChoiceLogic do
  @moduledoc """
  A choice logic is a design entity with full case one one input,
  picking output from 2^n of choices
  """

  alias Danm.Entity
  alias Danm.WireExpr

  use Bitwise, only_operators: true
  
  @doc """
  A choice logic is just a wrapper around a list of expr. output is a string
  inputs is a map of %{name => width}
  """
  defstruct [ :output, :condition, width: 0, choices: [], inputs: %{} ]

  defimpl Entity do

    def elaborate(b) do
      new_width = Enum.reduce(b.choices, 0, fn x, acc ->
	x |> WireExpr.width(in: b.inputs) |> max(acc)
      end)
      if new_width == b.width, do: b, else: %{b | width: new_width}
    end

    def name(b), do: b.output
    def doc_string(_), do: "Full case decoder"
    def type_string(_), do: "full case decoder"
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
  create a choice logic. all width assume to be 0 for now
  """
  def new(condition, choices, as: n) do
    [ _ | tail ] = choices |> Enum.count() |> Integer.digits(2)
    Enum.each(tail, fn d ->
      if d != 0, do: raise "choices must be power of 2 long" end) 
    map =
      [ condition | choices ]
      |> Enum.flat_map(fn x -> WireExpr.ids(x) end)
      |> Map.new(fn x -> {x, 0} end)
    %__MODULE__{condition: condition, choices: choices, output: n, inputs: map}
  end

  @doc """
  width of the condition
  """
  def cond_width(s), do: WireExpr.width(s.condition, in: s.inputs) 

  @doc """
  whether condition has the right width
  """
  def condition_width_match?(s), do: Enum.count(s.choices) === (1 <<< cond_width(s))

end
