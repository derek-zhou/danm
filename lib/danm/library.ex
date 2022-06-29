defmodule Danm.Library do
  @moduledoc false

  # name of the ETS table
  @ets_black_boxes :danm_black_boxes
  @ets_schematics :danm_schematics
  @ets_build_cache :danm_build_cache

  alias :ets, as: ETS
  alias Danm.Entity
  alias Danm.BlackBox
  alias Danm.Schematic

  def start do
    ETS.new(@ets_black_boxes, [:named_table])
    ETS.new(@ets_schematics, [:named_table])
    ETS.new(@ets_build_cache, [:named_table])
  end

  def stop do
    ETS.delete(@ets_build_cache)
    ETS.delete(@ets_schematics)
    ETS.delete(@ets_black_boxes)
  end

  defp load_black_box(name) do
    v_path = Application.get_env(:danm, :verilog_path, [])

    case ETS.lookup(@ets_black_boxes, name) do
      [] ->
        case Enum.find_value(v_path, fn p ->
               BlackBox.parse_verilog("#{p}/#{name}.v")
             end) do
          nil ->
            nil

          b ->
            ETS.insert(@ets_black_boxes, {name, b})
            b
        end

      [{^name, b}] ->
        b
    end
  end

  defp try_load_schematic(name) do
    # naming convention enforced
    m = String.to_atom("Elixir.Danm.Schematic." <> Macro.camelize(name))
    e_path = Application.get_env(:danm, :elixir_path, [])

    cond do
      Code.ensure_loaded?(m) ->
        %Schematic{name: name, module: m, src: "_BUILTIN"}

      true ->
        Enum.find_value(e_path, fn p ->
          try do
            Code.require_file("#{name}.exs", p)
            %Schematic{name: name, module: m, src: "#{p}/#{name}.exs"}
          rescue
            Code.LoadError -> nil
          end
        end)
    end
  end

  defp load_schematic(name) do
    case ETS.lookup(@ets_schematics, name) do
      [] ->
        case try_load_schematic(name) do
          nil ->
            nil

          s ->
            ETS.insert(@ets_schematics, {name, s})
            s
        end

      [{^name, s}] ->
        s
    end
  end

  defp load_module(name) do
    case load_schematic(name) do
      nil -> load_black_box(name)
      b -> b
    end
  end

  defp module_to_key(s), do: {s.name, s.params}

  defp build_module(m) do
    key = module_to_key(m)

    case ETS.lookup(@ets_build_cache, key) do
      [] ->
        s = Entity.elaborate(m)
        ETS.insert(@ets_build_cache, {key, s})
        s

      [{^key, s}] ->
        s
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
