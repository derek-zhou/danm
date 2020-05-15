defmodule Danm.CaseLogic do
  @moduledoc """
  A case logic is a design entity with a list of cases anf choices,
  output the choice when subject match the first case
  the laast could be nil, which will match everything
  """

  alias Danm.Entity
  alias Danm.WireExpr

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
    def doc_string(_), do: "Case decoder"
    def type_string(_), do: "case decoder"
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
  create a case logic. all width assume to be 0 for now
  """
  def new(subject, cases, choices, as: n) do
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
