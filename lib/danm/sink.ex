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
    def doc_string(_), do: "Just a sink"
    def type_string(_), do: "sink"
    def sub_modules(_), do: []
    def sub_module_at(_, _), do: nil
    def ports(b), do: b.inputs |> Map.keys()
    def port_at(b, name), do: (if b.inputs[name], do: {:input, b.inputs[name]})
  end

  @doc """
  add/change an input of a sink. all width assume to be 0 if absent
  """
  def set_input(b, n), do: %{b | inputs: Map.put(b.inputs, n, 0)}
  def set_input(b, n, w), do: %{b | inputs: Map.put(b.inputs, n, w)}

  @doc """
  create a sink. all width assume to be 0 for now
  """
  def new(n), do: %__MODULE__{inputs: %{n => 0}}
end
