defmodule Danm.CheckDesign do
  @moduledoc false

  require Logger

  alias Danm.WireExpr
  alias Danm.Entity
  alias Danm.BlackBox
  alias Danm.Schematic
  alias Danm.Sink
  alias Danm.ComboLogic
  alias Danm.BundleLogic
  alias Danm.ChoiceLogic
  alias Danm.ConditionLogic
  alias Danm.CaseLogic
  alias Danm.SeqLogic
  alias Danm.FiniteStateMachine
  alias Danm.Assertion

  defstruct dict: %{},
    stack: [],
    cache: %{},
    errors: 0,
    warnings: 0

  @doc ~S"""
  check design integrity and report errors and warnings. return {errors, warnings}
  """
  def check_design(s) do
    state = %__MODULE__{}
    |> check_design(s)
    {state.errors, state.warnings}
  end

  defp module_to_key(s) do
    case s.__struct__ do
      BlackBox -> {s.name, s.params}
      Schematic -> {s.name, s.params}
      _ -> s       # anything else should always has a unique key
    end
  end

  defp current_design(state), do: hd(state.stack)

  defp current_focus(state) do
    s = current_design(state)
    case s.__struct__ do
      t when t in [BlackBox, Schematic] -> s.name
      _ ->
	[logic, sch | _ ] = state.stack
	"#{sch.name}.#{Entity.name(logic)}"
    end
  end

  defp error(state, msg), do: error(state, msg, if: true)
  defp error(state, msg, if: bool) do
    cond do
      bool ->
	focus = current_focus(state)
	Logger.error("Check design ERROR: #{msg}, in #{focus}")
	%{state | errors: state.errors + 1}
      true -> state
    end
  end

  defp warning(state, msg), do: warning(state, msg, if: true)
  defp warning(state, msg, if: bool) do
    cond do
      bool ->
	focus = current_focus(state)
	Logger.warn(:stderr, "Check design WARNING: #{msg}, in #{focus}")
	%{state | warnings: state.warnings + 1}
      true -> state
    end
  end

  defp begin_check(state, key, s) do
    %{state |
      dict: Map.put(state.dict, key, :ongoing),
      stack: [s | state.stack ]}
  end

  defp end_check(state, key) do
    %{state |
      dict: Map.put(state.dict, key, :done),
      stack: tl(state.stack)}
  end

  defp check_design(state, s) do
    key = module_to_key(s)
    case Map.get(state.dict, key) do
      :done -> state
      :ongoing -> error(state, "Infinite recursive design")
      nil ->
	state
	|> begin_check(key, s)
	|> check_current_design()
	|> end_check(key)
    end
  end

  defp check_current_design(state) do
    case current_design(state).__struct__ do
      Sink -> state
      Assertion -> state
      BlackBox -> check_black_box_design(state)
      Schematic -> state |> check_instances() |> check_self_schematic()
      ComboLogic -> check_combo_logic(state)
      BundleLogic -> check_bundle_logic(state)
      ChoiceLogic -> check_choice_logic(state)
      ConditionLogic -> check_condition_logic(state)
      CaseLogic -> check_case_logic(state)
      SeqLogic -> check_seq_logic(state)
      FiniteStateMachine -> check_fsm_logic(state)
    end
  end

  defp check_black_box_design(state) do
    state |> check_params() |> check_ports()
  end

  defp check_params(state) do
    Enum.reduce(current_design(state).params, state, fn {k, v}, state ->
      error(state, "unresolved parameter: #{k}", if: !is_integer(v))
    end)
  end

  defp check_ports(state) do
    s = current_design(state)
    s.ports
    |> Enum.reduce(state, fn {p_name, {_, w}}, state ->
      error(state, "unresolved port width: #{p_name}", if: !is_integer(w))
    end)
  end

  defp check_self_schematic(state) do
    state |> calculate_cache_data() |> check_conns() |> check_wires()
  end

  defp check_instances(state) do
    s = current_design(state)
    s.insts
    |> Map.values()
    |> Enum.reduce(state, fn inst, state -> check_design(state, inst) end)
  end

  defp calculate_cache_data(state) do
    %{state |
      cache: Map.put(state.cache, :map,
	state |> current_design() |> Schematic.pin_to_wire_map()) }
  end

  defp check_conns(state) do
    map = state.cache.map
    s = current_design(state)
    s.insts
    |> Map.keys()
    |> Enum.reduce(state, fn i_name, state ->
      inst = Map.fetch!(s.insts, i_name)
      inst
      |> Entity.ports()
      |> Enum.reduce(state, fn p_name, state ->
	pin = "#{i_name}/#{p_name}"
	{dir, _} = Entity.port_at!(inst, p_name)
	cond do
	  Map.has_key?(map, pin) -> state
	  dir == :output -> warning(state, "unconnecterd output pin: #{pin}")
	  true -> error(state, "unconnecterd input pin: #{pin}")
	end
      end)
    end)
  end

  defp check_wires(state) do
    map = state.cache.map
    s = current_design(state)
    Enum.reduce(s.wires, state, fn {w_name, conns}, state ->
      {drivers, loads, width} = Schematic.inspect_wire(s, w_name)
      state = state
      |> error("undriven wire: #{w_name}", if: drivers == 0)
      |> error("multiple driven wire: #{w_name}", if: drivers > 1)
      |> error("unknown width in wire: #{w_name}", if: width == 0)
      |> warning("unloaded wire: #{w_name}", if: loads == 0)
      conns
      |> Enum.reject(fn {i_name, _} -> i_name == :self end)
      |> Enum.reduce(state, fn {i_name, p_name}, state ->
	pin = "#{i_name}/#{p_name}"
	wn2 = Map.fetch!(map, pin)
	{_, w2} = Entity.port_at!(Map.fetch!(s.insts, i_name), p_name)
	state
	|> error("multiple wire on pin: #{pin}", if: wn2 != w_name)
	|> error("wire width not match on pin: #{pin}, #{w2} != #{width}", if: w2 != width)
      end)
    end)
  end

  defp check_combo_logic(state) do
    s = current_design(state)
    error(state, "output looped back to input", if: ComboLogic.loop_back?(s))
  end

  defp check_bundle_logic(state) do
    s = current_design(state)
    case s.op do
      :comma -> state
      _ ->
	warning(state, "bundling wires with unmatched width",
	  if: !WireExpr.width_match?(s.exprs, in: s.inputs))
    end
    |> error("output looped back to input",
	  if: ComboLogic.loop_back?(s))
  end

  defp check_choice_logic(state) do
    s = current_design(state)
    state
    |> error("output looped back to input",
	  if: ComboLogic.loop_back?(s))
    |> error("condition in choice has wrong width",
          if: !ChoiceLogic.condition_width_match?(s))
    |> warning("choices have unmatched width",
	  if: !WireExpr.width_match?(s.choices, in: s.inputs))
  end

  defp check_condition_logic(state) do
    s = current_design(state)
    state
    |> error("output looped back to input",
	  if: ComboLogic.loop_back?(s))
    |> error("last condition must be always true",
          if: !ConditionLogic.last_is_true?(s))
    |> warning("choices have unmatched width",
          if: !WireExpr.width_match?(s.choices, in: s.inputs))
  end

  defp check_case_logic(state) do
    s = current_design(state)
    state
    |> error("output looped back to input",
	  if: ComboLogic.loop_back?(s))
    |> error("last case must be default",
          if: !CaseLogic.last_is_default?(s))
    |> warning("choices have unmatched width",
	  if: !WireExpr.width_match?(s.choices, in: s.inputs))
    |> warning("All cases must has matching width",
          if: !CaseLogic.width_match?(s))
  end

  # be explicit here
  defp check_seq_logic(state) do
    s = current_design(state)
    core = s.core
    case core.__struct__ do
      ComboLogic -> state
      BundleLogic ->
	case core.op do
	  :comma -> state
	  _ ->
	    warning(state, "bundling wires with unmatched width",
	      if: !WireExpr.width_match?(core.exprs, in: core.inputs))
	end
      ChoiceLogic ->
	state
	|> error("condition in choice has less than enough width",
          if: !ChoiceLogic.condition_width_enough?(core))
	|> warning("choices have unmatched width",
	  if: !WireExpr.width_match?(core.choices, in: core.inputs))
      ConditionLogic ->
	state
	|> warning("choices have unmatched width",
          if: !WireExpr.width_match?(core.choices, in: core.inputs))
      CaseLogic ->
	state
	|> warning("choices have unmatched width",
	  if: !WireExpr.width_match?(core.choices, in: core.inputs))
	|> warning("All cases must has matching width",
          if: !CaseLogic.width_match?(core))
    end
  end

  defp check_fsm_logic(state) do
    s = current_design(state)
    warning(state, "output looped back to condition clause of a FSM",
      if: ComboLogic.loop_back?(s))
  end

end
