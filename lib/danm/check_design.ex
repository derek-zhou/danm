defmodule Danm.CheckDesign do
  @moduledoc """
  perform design check on a design
  """

  alias Danm.BlackBox
  alias Danm.Schematic
  alias Danm.Sink

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
      Sink -> {"_sink", s.ports}
      _ -> {s.name, s.params}
    end
  end

  defp current_design(state), do: hd(state.stack)

  defp error(state, msg), do: error(state, msg, if: true)
  defp error(state, msg, if: bool) do
    cond do
      bool ->
	focus = current_design(state).name
	IO.write(:stderr, "Check design ERROR: #{msg}, in #{focus}\n")
	%{state | errors: state.errors + 1}
      true -> state
    end
  end

  defp warning(state, msg, if: bool) do
    cond do
      bool ->
	focus = current_design(state).name
	IO.write(:stderr, "Check design WARNING: #{msg}, in #{focus}\n")
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
    case state.dict[key] do
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
      BlackBox -> check_black_box_design(state)
      Schematic -> state |> check_instances() |> check_self_schematic()
      Sink -> state
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
    Enum.reduce(current_design(state).ports, state, fn {k, {_, w}}, state ->
      error(state, "unresolved port width: #{k}", if: !is_integer(w))
    end)
  end

  defp check_self_schematic(state) do
    state |> calculate_cache_data() |> check_conns() |> check_wires()
  end

  defp check_instances(state) do
    Enum.reduce(current_design(state).insts, state, fn {_, inst}, state ->
      check_design(state, inst) end)
  end

  defp calculate_cache_data(state) do
    %{state |
      cache: Map.put(state.cache, :map,
	state |> current_design() |> Schematic.pin_to_wire_map()) }
  end

  defp check_conns(state) do
    map = state.cache.map
    Enum.reduce(current_design(state).insts, state, fn {i_name, inst}, state ->
      Enum.reduce(inst.ports, state, fn {p_name, _}, state ->
	pin = "#{i_name}/#{p_name}"
	error(state, "unconnecterd pin: #{pin}", if: !Map.has_key?(map, pin))
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
	wn2 = map[pin]
	{_, w2} = s.insts[i_name].ports[p_name]
	state
	|> error("multiple wire on pin: #{pin}", if: wn2 != w_name)
	|> error("wire width not match on pin: #{pin}", if: w2 != width)
      end)
    end)
  end

end
