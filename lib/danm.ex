defmodule Danm do
  @moduledoc """
  Public API for `Danm`.
  """

  alias Danm.Library
  alias Danm.HtmlPrinting
  alias Danm.VerilogPrinting
  alias Danm.CheckDesign

  @doc ~S"""
  check design integrity and report errors and warnings. return false if there were errors
  optional arguments:

    * :check_warnings, when true, fail if there are warnings

  """
  def check_design(s, options \\ []) do
    {warnings, errors} = CheckDesign.check_design(s)
    (errors == 0) and (!options[:check_warnings] or (warnings == 0))
  end

  @doc ~S"""
  generate a single verilog file that have everything. File name is deduced from the design name
  """
  def generate_full_verilog(s, in: dir) do
    VerilogPrinting.generate_full_verilog(s, in: dir)
  end

  @doc ~S"""
  generate a full set of html files. top level is called top.html
  """
  def generate_html_as_top(s, in: dir) do
    HtmlPrinting.generate_html_hier(s, in: dir)
    HtmlPrinting.generate_html(s, as: "top", in: dir)
  end

  @doc ~S"""
  build the design with "name" from top down
  optional arguments:

    * :verilog_path, a list of paths to search for verilog black boxes
    * :elixir_path, a list of paths to search for elixir schematics in exs
    * :parameters, a map of additional parameters to set to top level before elaborate

  """
  def build(name, options \\ []) do
    Library.start_link(options[:verilog_path] || [], options[:elixir_path] || [])
    m = Library.load_and_build_module(name, options[:parameters] || %{})
    Library.stop()
    m
  end

  @doc ~S"""
  build, check design, generate html and verilog for one or several designs,
  all in one go, with config pulled in from config file. In your config.exs, you may want to have:


  ``` elixir
  config :danm,
  verilog_path: [PATH1, PATH2],
  elixir_path: [PATH3, PATH4],
  check_warning: true,
  default_params: %{
    "DESIGN1" => %{
      "SOMETHING" => VALUE,
    }
  }
  ```
  Please see the other functions of this module to see find out the meaning of those configs.
  """
  def auto_build(names) do
    v_path =
      case Application.fetch_env(:danm, :verilog_path) do
	{:ok, path} -> path
	_ -> []
      end
    e_path =
      case Application.fetch_env(:danm, :elixir_path) do
	{:ok, path} -> path
	_ -> []
      end
    output_dir =
      case Application.fetch_env(:danm, :output_dir) do
	{:ok, path} -> path
	_ -> "obj"
      end
    default_params =
      case Application.fetch_env(:danm, :default_params) do
	{:ok, map} -> map
	_ -> %{}
      end
    check_warning =
      case Application.fetch_env(:danm, :check_warning) do
	{:ok, v} -> v
	_ -> false
      end

    File.mkdir_p!(output_dir)
    Library.start_link(v_path, e_path)
    names = List.wrap(names)

    Enum.each(names, fn name ->
      mod = Library.load_and_build_module(name, default_params[name] || %{})
      unless check_design(mod, check_warnings: check_warning) do
	raise("check design failed for design #{name}")
      end
      File.mkdir_p!("#{output_dir}/#{name}_html")
      generate_html_as_top(mod, in: "#{output_dir}/#{name}_html")
      generate_full_verilog(mod, in: "#{output_dir}")
    end)

    Library.stop()
  end

end
