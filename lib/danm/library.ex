defmodule Danm.Library do
  @moduledoc """
  Loading modules from the filesystem
  """

  alias Danm.Entity
  alias Danm.BlackBox
  alias Danm.Schematic
  
  use Agent

  defstruct verilog_path: [],
    black_boxes: %{},
    elixir_path: [],
    schematics: %{},
    build_cache: %{}

  defp set_black_box(l, n, to: b), do: %{l | black_boxes: Map.put(l.black_boxes, n, b)}
  defp set_schematic(l, n, to: s), do: %{l | schematics: Map.put(l.schematics, n, s)}

  def start_link(vp, ep) do
    Agent.start_link(
      fn ->
	%__MODULE__{verilog_path: vp, elixir_path: ep}
      end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end

  def stop do
    Agent.stop(__MODULE__)
  end
  
  @doc """
  load_black_box(l, name)
  load the black box by name in library l, return {b, new_l}
  """
  def load_black_box(l, name) do
    case Map.get(l.black_boxes, name) do
      nil ->
	case Enum.find_value(l.verilog_path, fn p ->
	      BlackBox.parse_verilog("#{p}/#{name}.v")
	    end) do
	  nil -> {nil, l}
	  b -> {b, set_black_box(l, name, to: b)}
	end
      b -> {b, l}
    end
  end

  @doc """
  load_schematic(l, name)
  load the black box by name in library l, return {b, new_l}
  """
  def load_schematic(l, name) do
    case Map.get(l.schematics, name) do
      nil ->
	case Enum.find_value(l.elixir_path, fn p ->
	      try do
		Code.require_file("#{name}.exs", p)
		# naming convention enforced
		m = String.to_atom("Elixir.Danm.Schematic." <> Macro.camelize(name))
		%Schematic{name: name, module: m, src: "#{p}/#{name}.exs"}
	      rescue
		Code.LoadError -> nil
	      end
	    end) do
	  nil -> {nil, l}
	  s -> {s, set_schematic(l, name, to: s)}
	end
      s -> {s, l}
    end
  end

  @doc """
  load_module(l, name)
  load the module by name in library l, return {b, new_l}
  first try schematic, if fail, try black box
  """
  def load_module(l, name) do
    case load_schematic(l, name) do
      {nil, l} -> load_black_box(l, name)
      {b, l} -> {b, l}
    end
  end

  @doc """
  load_module(name)
  load the black box by name with the agent shared library
  """
  def load_module(name) do
    case Agent.get_and_update(__MODULE__, __MODULE__, :load_module, [name]) do
      nil -> raise "Module by the name of #{name} is not found"
      b -> b
    end
  end

  defp module_to_key(s), do: {s.name, s.params}

  @doc """
  build the module with the shared library
  """
  def build_module(m) do
    key = module_to_key(m)
    # I cannot use get_and_update because elaborate may call the agent again
    case Agent.get(__MODULE__, fn l -> Map.get(l.build_cache, key) end) do
      nil ->
	s = Entity.elaborate(m)
	Agent.update(__MODULE__, fn l -> %{l | build_cache: Map.put(l.build_cache, key, s)} end)
	s
      s -> s
    end
  end

  @doc """
  load, parameterize and build module
  """
  def load_and_build_module(name, params) do
    name
    |> load_module()
    |> BlackBox.merge_parameters(params)
    |> build_module()
  end

end
