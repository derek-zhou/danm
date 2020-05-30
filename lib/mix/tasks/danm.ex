defmodule Mix.Tasks.Danm do
  @moduledoc ~S"""
  run Danm in the current project to build designs.
  a list of designs is given in the arguments, config is pulled out from config
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
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
    Enum.each(args, fn name ->
      params = default_params[name] || %{}
      build_one(name, v_path, e_path, output_dir, params, check_warning)
    end)
  end
  
  defp build_one(name, v_path, e_path, output_dir, params, check_warning) do
    import Danm
    
    mod = build(name, verilog_path: v_path, elixir_path: e_path, parameters: params)
    unless check_design(mod, check_warnings: check_warning), do: raise("check design failed")
    File.mkdir_p!("#{output_dir}/#{name}_html")
    generate_html_as_top(mod, in: "#{output_dir}/#{name}_html")
    generate_full_verilog(mod, in: "#{output_dir}")
  end

end
