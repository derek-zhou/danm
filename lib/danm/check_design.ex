defmodule Danm.CheckDesign do
  @moduledoc """
  perform design check on a design
  """

  alias Danm.BlackBox
  alias Danm.Schematic

  defstruct dict: %{},
    stack: [],
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

  defp module_to_key(s), do: {s.name, s.params}

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

  defp warning(state, msg), do: warning(state, msg, if: true)
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
	|> check_one_design(s)
	|> end_check(key)
    end
  end

  defp check_one_design(state, s) do
    case s.__struct__ do
      BlackBox -> check_black_box_design(state, s)
      Schematic -> check_schematic_design(state, s)
    end
  end

  defp check_black_box_design(state, b) do
    state |> check_params(b) |> check_ports(b)
  end

  defp check_params(state, b) do
    Enum.reduce(b.params, state, fn {k, v}, state ->
      error(state, "unresolved parameter: #{k}", if: !is_integer(v))
    end)
  end

  defp check_ports(state, b) do
    Enum.reduce(b.ports, state, fn {k, {_, w}}, state ->
      error(state, "unresolved port width: #{k}", if: !is_integer(w))
    end)
  end

  defp check_schematic_design(state, s) do
    map = Schematic.pin_to_wire_map(s)
    state |> check_instances(s) |> check_conns(s, map) |> check_wires(s, map)
  end

  defp check_instances(state, s) do
    Enum.reduce(s.insts, state, fn {_, inst}, state -> check_design(state, inst) end)
  end

  defp check_conns(state, s, map) do
    Enum.reduce(s.insts, state, fn {i_name, inst}, state ->
      Enum.reduce(inst.ports, state, fn {p_name, _}, state ->
	pin = "#{i_name}/#{p_name}"
	error(state, "unconnecterd pin: #{pin}", if: !Map.has_key?(map, pin))
      end)
    end)
  end

  defp check_wires(state, s, map) do
    Enum.reduce(s.wires, state, fn {w_name, conns}, state ->
      {drivers, loads, width} = Schematic.inspect_wire(s, w_name)
      state = state
      |> error("undriven wire: #{w_name}", if: drivers == 0)
      |> error("multiple driven wire: #{w_name}", if: drivers > 1)
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
