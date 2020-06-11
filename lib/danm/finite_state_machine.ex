defmodule Danm.FiniteStateMachine do
  @moduledoc ~S"""
  A finite state machine is a design entity with a flopped output that represent a state.
  The next state depend on the current state and various inputs
  The state transfer graph can be expressed as a following:
  ```
  [
  {:state0, {{condition, next_state},
             {condition, next_state},
             ...},
  {:state1, {{condition, next_state},
             {condition, next_state},
             ...},
  ...
  ]
  ```
  each possible state is represented as a atom. conditions are expressions
  """

  alias Danm.Entity
  alias Danm.WireExpr
  alias Danm.ComboLogic

  @doc """
  A finite state machine has a state transfer graph, a reset clause, a name, clock and width
  clk is a string of the clock name
  """
  defstruct [ :graph, :lut, :clk, :output, width: 0, inputs: %{}]

  defimpl Entity do

    def elaborate(b), do: b
    def name(b), do: b.output
    def type_string(_), do: "FSM logic"

    def ports(b), do: [b.clk | ComboLogic.ports(b)]

    def port_at!(b, name) do
      cond do
	name == b.clk -> {:input, 1}
	true -> ComboLogic.port_at!(b, name)
      end
    end

    def has_port?(b, name) do
      cond do
	name == b.clk -> true
	true -> ComboLogic.has_port?(b, name)
      end
    end

  end

  @doc """
  create a FSM logic
  """
  def new(graph, clk, reset_by: reset, as: n) do
    lut = state_lut(graph)
    reset = reset && WireExpr.parse(reset)
    graph = parse_graph(graph, lut, reset)
    map = input_map(graph)
    width = width_of(graph)
    %__MODULE__{graph: graph, lut: lut, clk: clk, output: n, width: width, inputs: map}
  end

  defp width_of(list), do: Enum.count(list) - 1 |> Integer.digits(2) |> Enum.count()

  defp input_map(graph) do
    graph
    |> Enum.flat_map(fn {_, list} ->
         Enum.map(list, fn {condition, _} -> condition end)
       end)
    |> Enum.flat_map(fn x -> WireExpr.ids(x) end)
    |> Map.new(fn x -> {x, 0} end)
  end

  defp state_lut(list) do
    list
    |> Enum.map(fn {state, _} -> state end)
    |> Enum.zip(0 .. Enum.count(list) - 1)
    |> Map.new()
  end

  defp add_reset_clause(list, reset) do
    case reset do
      nil -> list
      _ -> [{reset, 0} | list]
    end
  end

  defp parse_graph(graph, lut, reset) do
    Enum.map(graph, fn {state, transit} ->
      {Map.fetch!(lut, state), transit |> parse_transit(lut) |> add_reset_clause(reset)}
    end)
  end

  defp parse_transit(list, lut) do
    Enum.map(list, fn {condition, next_state} ->
      {WireExpr.parse(condition), Map.fetch!(lut, next_state)}
    end)
  end

end
