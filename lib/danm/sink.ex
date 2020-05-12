defmodule Danm.Sink do
  @moduledoc """
  A sink is a design entity with some input ports and not output
  """

  alias Danm.Entity

  @doc """
  A sink is super simple, however I need to make it a full struct to be an entity
  """
  defstruct ports: %{}

  defimpl Entity do

    def elaborate(b), do: b
    def doc_string(_), do: "Just a sink"
    def type_string(_), do: "sink"
    def sub_modules(_), do: []
    def sub_module_at(_, _), do: nil
    def ports(b), do: b.ports |> Map.keys()
    def port_at(b, name), do: (if b.ports[name], do: {:input, b.ports[name]})
  end

  def set_port(b, n, w), do: %{b | ports: Map.put(b.ports, n, w)}
  def new_sink(n, w), do: %__MODULE__{ports: %{n => w}}
end
