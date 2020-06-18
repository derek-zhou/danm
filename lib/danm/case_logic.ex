defmodule Danm.CaseLogic do
  @moduledoc false

  alias Danm.Entity
  alias Danm.WireExpr
  alias Danm.ComboLogic

  @doc """
  A case logic is just a wrapper around a list of expr. output is a string
  inputs is a map of %{name => width}
  """
  defstruct [ :output, :subject, width: 0, cases: [], choices: [], inputs: %{} ]

  defimpl Entity do

    def elaborate(b) do
      new_width = Enum.reduce(b.choices, 0, fn x, acc ->
	x |> WireExpr.width(in: b.inputs) |> max(acc)
      end)
      if new_width == b.width, do: b, else: %{b | width: new_width}
    end

    def name(b), do: b.output
    def type_string(_), do: "case decoder"
    def ports(b), do: ComboLogic.ports(b)
    def port_at!(b, name), do: ComboLogic.port_at!(b, name)
    def has_port?(b, name), do: ComboLogic.has_port?(b, name)

  end

  @doc """
  create a case logic. all width assume to be 0 for now
  """
  def new(subject, list, as: n) do
    subject = WireExpr.parse(subject)
    cases = Enum.map(list, fn {str, _} -> WireExpr.parse(str) end)
    choices = Enum.map(list, fn {_, str} -> WireExpr.parse(str) end)
    map =
      [subject | (cases ++ choices)]
      |> Enum.flat_map(fn x -> WireExpr.ids(x) end)
      |> Map.new(fn x -> {x, 0} end)
    %__MODULE__{subject: subject, cases: cases, choices: choices, output: n, inputs: map}
  end

  @doc """
  check if last case is default
  """
  def last_is_default?(s), do: Enum.at(s.cases, -1) == nil

  @doc """
  check if subject's width match all cases, unless case is nil
  """
  def width_match?(s) do
    sw = WireExpr.width(s.subject, in: s.inputs)
    Enum.all?(s.cases, fn c -> c == nil or WireExpr.width(c, in: s.inputs) == sw end)
  end
  
end
