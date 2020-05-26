defmodule Danm.SeqLogic do
  @moduledoc """
  A seq logic is a design entity with some input ports and one output, and the output
  is derived from input and itself in a sequential way
  """

  alias Danm.Entity
  alias Danm.ComboLogic

  @doc """
  A seq logic is just a wrapper another design entity, like combo logic, bundle logic,
  choice logic, condition logic or case logic. aditional sequential element is added
  core is the wrapped combinatorial logic. 
  clk cannot be nil. 
  """
  defstruct [ :core, :clk ]

  defimpl Entity do

    def elaborate(b) do
      new_core = Entity.elaborate(b.core)
      if new_core == b.core, do: b, else: %{b | core: new_core}
    end

    def name(b), do: b.core.output
    def type_string(_), do: "sequential logic"
    
    def ports(b), do: [b.clk | ComboLogic.ports(b.core) ]

    def port_at(b, name) do
      cond do
	name == b.clk -> {:input, 1}
	true -> ComboLogic.port_at(b.core, name)
      end
    end

  end

  @doc """
  create a seq logic
  """
  def new(core, clk), do: %__MODULE__{core: core, clk: clk}

end
