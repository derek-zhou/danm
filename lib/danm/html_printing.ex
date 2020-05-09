defmodule Danm.HtmlPrinting do
  @moduledoc """
  Generate HTML documents
  """

  alias Danm.Schematic

  @doc ~S"""
  generate a hier index to the set of html files
  """
  def generate_html_hier(s, in: dir) do
    f = File.open!("#{dir}/hierarchy.html", [:write, :utf8])
    IO.write(f, ~s"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <title>Module Hierachy</title>
    </head>
    <body>
    <p><a href="hierarchy.html">Hierarchy</a> | <a href="top.html">Top</a></p>
    <h1>Module Hierarchy</h1>
    <div id="tree">
    """)
    print_html_hier(s, f, as: "top")
    IO.write(f, ~s"""
    </div>
    <hr/><p>This document is generated by DANM on #{DateTime.utc_now()}</p>
    </body>
    </html>
    """)
    File.close(f)
    s
  end

  @doc ~S"""
  print html fragment that contains hier index to f
  """
  def print_html_hier(s, f, as: hier) do
    if s.__struct__ == Danm.Schematic and !Enum.empty?(s.insts) do
      IO.write(f, "<ul>\n")
      Enum.each(s.insts, fn {i_name, inst} ->
	IO.write(f, ~s"""
	<li><a href="#{hier}/#{i_name}.html">#{i_name}</a>
	(#{Schematic.type_string(inst)})</li>
	""")
	print_html_hier(inst, f, as: hier <> "/" <> i_name)
      end)
      IO.write(f, "</ul>\n")
    end
    s
  end

  @doc ~S"""
  generate html for myself and everything below
  """
  def generate_html(s, as: hier, in: dir) do
    if s.__struct__ == Danm.Schematic and !Enum.empty?(s.insts) do
      File.mkdir("#{dir}/#{hier}")
      Enum.each(s.insts, fn {i_name, inst} ->
	generate_html(inst, as: "#{hier}/#{i_name}", in: dir)
      end)
    end
    generate_own_html(s, as: hier, in: dir)
  end

  @doc ~S"""
  generate html for myself only
  """
  def generate_own_html(s, as: hier, in: dir) do
    f = File.open!("#{dir}/#{hier}.html", [:write, :utf8])
    print_html_header(s, f, as: hier)
    print_html_ports(s, f)
    if s.__struct__ == Danm.Schematic and !Enum.empty?(s.insts) do
      print_html_instance_summary(s, f, as: hier)
      map = Schematic.pin_to_wire_map(s)
      IO.write(f, "<ul>\n")
      Enum.each(s.insts, fn {i_name, inst} ->
	print_html_instance(inst, f, as: "#{hier}/#{i_name}", lookup: map)
      end)
      IO.write(f, "</ul><hr/>\n")
    end
    print_html_wires(s, f, as: hier)
    print_html_footer(f)
    File.close(f)
    s
  end

  defp get_self_and_up_module(hier) do
    hier
    |> Path.split()
    |> Enum.reverse()
    |> case do
	 [h0, h1 | _ ] -> {h0, h1}
	 [h0 | _ ] -> {h0, nil}
       end
  end

  defp get_top_path(hier) do
    hier |> Path.split() |> tl() |> Enum.map(fn _ -> "../" end) |> Enum.join()
  end

  defp print_html_header(s, f, as: hier) do
    title = "#{hier} (#{Schematic.type_string(s)}) Documentation"
    {self_module, up_module} = get_self_and_up_module(hier)
    top_path = get_top_path(hier)
    IO.write(f, ~s"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <title>#{title}</title>
    <style>
    table { border: 1px solid black; border-collapse: collapse; }
    th, td { border: 1px solid black; padding: 0.25em 1em; text-align: left; }
    tr:nth-child(even) {background-color: #f2f2f2;}
    </style>
    </head>
    <body>
    <p><a href="#{top_path}hierarchy.html">Hierarchy</a>
    """)
    if up_module do
      IO.write(f, ~s"""
      | <a href="../#{up_module}.html#INST_#{self_module}">Up (#{up_module})</a>
      """)
    end
    IO.write(f, ~s"""
    | <a href="#{top_path}top.html">Top</a>
    <h1>#{title}</h1>
    <p>#{Schematic.doc_string(s)}</p>
    <p>Defined in: #{s.src}</p><hr/>
    """)
    s
  end

  defp print_html_ports(s, f) do
    IO.write(f, ~s"""
    <h2>Port Summary</h2><table>
    <tr><th>port</th><th>direction</th><th>width</th></tr>
    """)
    s.ports
    |> Map.keys()
    |> Enum.sort(:asc)
    |> Enum.each(fn p_name ->
      {dir, width} = s.ports[p_name]
      IO.write(f, ~s"""
      <tr><td><a href="#WIRE_#{p_name}">#{p_name}</a></td><td>#{dir}</td><td>#{width}</td></tr>
      """)
    end)
    IO.write(f, "</table><hr/>\n")
    s
  end

  defp print_html_instance_summary(s, f, as: hier) do
    {self_module, _} = get_self_and_up_module(hier)
    count = Enum.count(s.insts)
    IO.write(f, "<h2>#{count} Instances</h2><table><tr><th>instance</th><th>module</th></tr>\n")
    s.insts
    |> Map.keys()
    |> Enum.sort(:asc)
    |> Enum.each(fn i_name ->
      inst = s.insts[i_name]
      IO.write(f, ~s"""
      <tr><td><a href="#INST_#{i_name}">#{i_name}</a></td><td><a href="#{self_module}/#{i_name}.html">#{inst.name}</a></td></tr>
      """)
    end)
    IO.write(f, "</table>\n")
    s
  end

  defp print_html_instance(s, f, as: hier, lookup: map) do
    {self_module, up_module} = get_self_and_up_module(hier)
    IO.write(f, ~s"""
    <li><h3>Instance <a id="INST_#{self_module}">#{self_module}</a>
    <a href="#{up_module}/#{self_module}.html">(#{s.name})</a></h3>
    <ul><li>Defined in: #{s.src}</li>
    <li>Connections:<table>
    <tr><th>port</th><th>direction</th><th>wire</th></tr>
    """)
    s.ports
    |> Map.keys()
    |> Enum.sort(:asc)
    |> Enum.each(fn p_name ->
      {dir, _} = s.ports[p_name]
      w_name = map["#{self_module}/#{p_name}"]
      IO.write(f, ~s"""
      <tr><td><a href="#{up_module}/#{self_module}.html#WIRE_#{p_name}">#{p_name}</a></td><td>#{dir}</td><td><a href="#WIRE_#{w_name}">#{w_name}</a></td></tr>
    """)
    end)
    IO.write(f, "</table></li>\n")
    unless Enum.empty?(s.params) do
      IO.write(f, "<li>Parameters:<table><tr><th>parameter</th><th>value</th></tr>\n")
      s.params
      |> Map.keys()
      |> Enum.sort(:asc)
      |> Enum.each(fn p_name ->
	p_v = s.params[p_name]
	IO.write(f, "<tr><td>#{p_name}</td><td>#{p_v}</td></tr>\n")
      end)
      IO.write(f, "</table></li>\n")
    end
    IO.write(f, "</ul></li>\n")
  end

  defp print_html_wires(s, f, as: hier) do
    {self_module, up_module} = get_self_and_up_module(hier)
    count = case s.__struct__ do
	      Danm.BlackBox -> Enum.count(s.ports)
	      Danm.Schematic -> Enum.count(s.wires)
	    end
    IO.write(f, "<h2>#{count} wires</h2><ul>\n")
    case s.__struct__ do
      Danm.BlackBox ->
	Enum.each(s.ports, fn {p_name, port} ->
	  print_html_port(port, f, as: p_name, self: self_module, up: up_module)
	end)
      Danm.Schematic ->
	map = Schematic.wire_width_map(s)
	Enum.each(s.wires, fn {w_name, conns} ->
	  conns
	  |> Enum.reject(fn {i, _} -> i == :self end)
	  |> print_html_wire(f,
	    as: w_name,
	    width: map[w_name],
	    port: s.ports[w_name],
	    self: self_module,
	    up: up_module)
	end)
    end
    IO.write(f, "</ul><hr/>\n")
  end

  defp print_html_port({dir, width}, f, as: p_name, self: self, up: up) do
    IO.write(f, ~s"""
    <li><h3>Wire <a id="WIRE_#{p_name}">#{p_name}</a></h3><ul>
    <li>width:#{width}</li>
    #{html_port_li(p_name, dir, self, up)}
    </ul></li>
    """)
  end

  defp html_port_li(p_name, dir, self, up) do
    case up do
      nil -> "<li>#{dir} port</li>"
      _ -> "<li><a href=\"../#{up}.html#PIN_#{self}/#{p_name}\">#{dir} port</a></li>"
    end
  end

  defp print_html_wire(conns, f, as: w_name, width: width, port: port, self: self, up: up) do
    IO.write(f, ~s"""
    <li><h3>Wire <a id="WIRE_#{w_name}">#{w_name}</a></h3><ul>
    <li>width:#{width}</li>
    """)
    if port do
      {dir, _} = port
      IO.write(f, html_port_li(w_name, dir, self, up))
    end
    unless Enum.empty?(conns) do
      IO.write(f, "<li>connections: <table><tr><th>instance</th><th>port</th></tr>\n")
      Enum.each(conns, fn {ins, port} ->
	IO.write(f, ~s"""
	<tr><td><a href="#INST_#{ins}">#{ins}</a></td><td><a id="PIN_#{ins}/#{port}" href="#{self}/#{ins}.html#WIRE_#{port}">#{port}</a></td></tr>
	""")
      end)
      IO.write(f, "</table></li>\n")
    end
    IO.write(f, "</ul></li>\n")
  end

  defp print_html_footer(f) do
    IO.write(f, ~s"""
    <p>This document is generated by DANM on #{DateTime.utc_now()}</p>
    </body></html>
    """)
  end

end
