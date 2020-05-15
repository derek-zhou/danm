defmodule Danm.Sink do
  @moduledoc """
  A sink is a design entity with some input ports and not output
  """

  alias Danm.Entity

  @doc """
  A sink is super simple, however I need to make it a full struct to be an entity
  """
  defstruct inputs: %{}

  defimpl Entity do

    def elaborate(b), do: b
    def name(_), do: "_sink"
    def doc_string(_), do: "Just a sink"
    def type_string(_), do: "sink"
    def ports(b), do: b.inputs |> Map.keys()
    def port_at(b, name), do: (if b.inputs[name], do: {:input, b.inputs[name]})
  end

  @doc """
  set the width of one input
  """
  def set_input(b, n, w), do: %{b | inputs: Map.replace!(b.inputs, n, w)}

  @doc """
  create a sink. all width assume to be 0 for now
  """
  def new(inputs), do: %__MODULE__{inputs: Map.new(inputs, fn x -> {x, 0} end)}

  @doc """
  merge a sink
  """
  def merge(b, inputs) do
    %{b | inputs: Map.merge(b.inputs, Map.new(inputs, fn x -> {x, 0} end))}
  end

end
