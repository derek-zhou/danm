defmodule Danm.VerilogPrinting do
  @moduledoc """
  Generate Verilog file for downstream tools
  """

  alias Danm.BlackBox
  alias Danm.Schematic

  defstruct dict: %{},
    stack: [],
    stream: nil,
    refs: %{}

  @doc ~S"""
  generate a single verilog file that have everything
  """
  def generate_full_verilog(s, in: dir) do
    f = File.open!("#{dir}/#{s.name}.v", [:write, :utf8])
    IO.write(f, ~s"""
    // This file is generated by DANM on #{DateTime.utc_now()}
    """)
    %__MODULE__{stream: f}
    |> setup_key_ref(module_to_key(s), s.name)
    |> print_full_verilog(s)
    File.close(f)
  end

  defp current_design(state), do: hd(state.stack)

  defp begin_print(state, ref, s) do
    %{state |
      refs: Map.put(state.refs, ref, :ongoing),
      stack: [s | state.stack ]}
  end

  defp end_print(state, ref) do
    %{state |
      refs: Map.put(state.refs, ref, :done),
      stack: tl(state.stack) }
  end

  defp print_full_verilog(state, s) do
    ref = state.dict[module_to_key(s)]
    case state.refs[ref] do
      :done -> state
      :ongoing -> raise "Infinite recursive design in #{s.name}"
      :todo ->
	state
	|> begin_print(ref, s)
	|> print_current_design(ref)
	|> end_print(ref)
    end
  end

  defp print_current_design(state, ref) do
    s = current_design(state)
    case s.__struct__ do
      BlackBox -> copy_self_verilog(state, ref)
      Schematic ->
	Enum.reduce(s.insts, print_self_verilog(state, ref), fn {_, inst}, state ->
	  print_full_verilog(state, inst) end)
    end
  end

  defp copy_self_verilog(state, ref) do
    b = current_design(state)
    f = state.stream
    if ref != b.name, do: raise "A black box cannot be uniquified, got #{ref} expect #{b.name}"
    # copy everything, and add a return to make sure format is proper
    IO.write(f, File.read!(b.src))
    IO.write(f, "\n")
    state
  end

  defp unique_name_like(name, from: dict) do
    cond do
      Map.has_key?(dict, name) -> unique_name_like(name, from: dict, salt: 1)
      true -> name
    end
  end

  defp unique_name_like(name, from: dict, salt: s) do
    salted = "#{name}_#{s}"
    cond do
      Map.has_key?(dict, salted) -> unique_name_like(name, from: dict, salt: s + 1)
      true -> salted
    end
  end

  defp print_self_verilog(state, ref) do
    s = current_design(state)
    f = state.stream
    sorted_ports = s.ports
    |> Map.keys()
    |> Enum.sort(fn a, b -> compare_port(dir_of(a, s), a, dir_of(b, s), b) end)

    port_string = Enum.join(sorted_ports, ",\n\t")
    IO.write(f, ~s"""
    /**
    #{Schematic.doc_string(s)}
    */
    module #{ref}(
    	#{port_string});

    """)
    Enum.each(sorted_ports, fn p_name ->
      {dir, width} = s.ports[p_name]
      case width do
	1 -> IO.write(f, "    #{dir} #{p_name};\n")
	_ -> IO.write(f, "    #{dir} [#{width - 1}:0] #{p_name};\n")
      end
    end)

    s.params
    |> Map.keys()
    |> Enum.sort(:asc)
    |> Enum.each(fn p_name ->
      p_value = s.params[p_name]
      IO.write(f, "    parameter #{p_name} = #{p_value};\n")
    end)

    map = Schematic.wire_width_map(s)
    s.wires
    |> Map.keys()
    |> Enum.reject(fn x -> Map.has_key?(s.ports, x) end)
    |> Enum.sort(:asc)
    |> Enum.each(fn w_name ->
      width = map[w_name]
      case width do
	1 -> IO.write(f, "    wire #{w_name};\n")
	_ -> IO.write(f, "    wire [#{width - 1}:0] #{w_name};\n")
      end
    end)
    IO.write(f, "\n")

    map = Schematic.pin_to_wire_map(s)
    state = s.insts
    |> Map.keys()
    |> Enum.sort(:asc)
    |> Enum.reduce(state, fn i_name, state ->
      print_one_instance(state, i_name, with: map)
    end)

    IO.write(f, "endmodule // #{ref}\n\n")
    state
  end

  defp compare_port(dir_a, a, dir_b, b) do
    cond do
      dir_a < dir_b -> true
      dir_a > dir_b -> false
      true -> a <= b
    end
  end

  defp module_to_key(s) do
    case s.__struct__ do
      BlackBox -> s.name
      Schematic -> {s.name, s.params}
    end
  end

  defp key_to_ref(state, k) do
    case state.dict[k] do
      nil ->
	name = case k do
		 {name, _} -> name
		 name -> name
	       end
	unique_name_like(name, from: state.dict)
      ref -> ref
    end
  end
  
  defp setup_key_ref(state, key, ref) do
    %{state |
      dict: Map.put(state.dict, key, ref),
      refs: case state.refs[ref] do
	      :done -> state.refs
	      _ -> Map.put(state.refs, ref, :todo)
	    end}
  end

  defp dir_of(p, s), do: elem(s.ports[p], 0)

  defp print_one_instance(state, i_name, with: map) do
    s = current_design(state)
    f = state.stream
    inst = s.insts[i_name]
    key = module_to_key(inst)
    ref = key_to_ref(state, key)
    IO.write(f, ~s"""
    // instance of #{Schematic.type_string(inst)}}
        #{ref} #{i_name}(
    """)

    conns_str = inst.ports
    |> Map.keys()
    |> Enum.sort(fn a, b -> compare_port(dir_of(a, inst), a, dir_of(b, inst), b) end)
    |> Enum.filter(fn p_name -> Map.has_key?(map, "#{i_name}/#{p_name}") end)
    |> Enum.map(fn p_name -> ".#{p_name}("<>map["#{i_name}/#{p_name}"] <> ")" end)
    |> Enum.join(",\n\t")

    IO.write(f, "\t#{conns_str});\n")
    inst.params
    |> Map.keys()
    |> Enum.sort(:asc)
    |> Enum.each(fn p_name ->
      p_value = inst.params[p_name]
      IO.write(f, "    defparam #{i_name}.#{p_name} = #{p_value};\n")
    end)
    IO.write(f, "\n")
    setup_key_ref(state, key, ref)
  end

end
