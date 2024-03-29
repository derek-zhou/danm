defmodule Danm.ChoiceLogic do
  @moduledoc false

  alias Danm.Entity
  alias Danm.WireExpr
  alias Danm.ComboLogic

  use Bitwise, only_operators: true

  @doc """
  A choice logic is just a wrapper around a list of expr. output is a string
  inputs is a map of %{name => width}
  """
  defstruct [:output, :condition, width: 0, choices: [], inputs: %{}]

  defimpl Entity do
    def elaborate(b) do
      new_width =
        Enum.reduce(b.choices, 0, fn x, acc ->
          x |> WireExpr.width(in: b.inputs) |> max(acc)
        end)

      if new_width == b.width, do: b, else: %{b | width: new_width}
    end

    def name(b), do: b.output
    def type_string(_), do: "full case decoder"
    def ports(b), do: ComboLogic.ports(b)
    def port_at!(b, name), do: ComboLogic.port_at!(b, name)
    def has_port?(b, name), do: ComboLogic.has_port?(b, name)
  end

  @doc """
  create a choice logic. all width assume to be 0 for now
  """
  def new(condition, choices, as: n) do
    condition = WireExpr.parse(condition)
    choices = Enum.map(choices, fn str -> WireExpr.parse(str) end)

    map =
      [condition | choices]
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
  def condition_width_match?(s), do: Enum.count(s.choices) == 1 <<< cond_width(s)

  @doc """
  whether condition has the enough width
  """
  def condition_width_enough?(s), do: Enum.count(s.choices) <= 1 <<< cond_width(s)
end
