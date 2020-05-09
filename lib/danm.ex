defmodule Danm do
  @moduledoc """
  Public API for `Danm`.
  """

  alias Danm.Library
  alias Danm.Schematic
  alias Danm.BlackBox
  alias Danm.HtmlPrinting
  alias Danm.VerilogPrinting

  @doc ~S"""
  generate a single verilog file that have everything
  """
  def generate_full_verilog(s, in: dir) do
    VerilogPrinting.generate_full_verilog(s, in: dir)
  end

  @doc ~S"""
  generate a full set of html files
  """
  def generate_html_as_top(s, in: dir) do
    HtmlPrinting.generate_html_hier(s, in: dir)
    HtmlPrinting.generate_html(s, as: "top", in: dir)
  end

  @doc ~S"""
  build the design with "name" from top down
  optional arguments:

    * :verilog_path, a list of paths to search for verilog black boxes
    * :elixir_path, a list of paths to search for elixir schematics
    * :parameters, a map of additional parameters to set before elaborate

  """
  def build(name, options \\ []) do
    name
    |> wrap(Library.start_link(options[:verilog_path] || [], options[:elixir_path] || []))
    |> Library.load_module()
    |> BlackBox.merge_parameters(options[:parameters] || %{})
    |> Library.build_module()
    |> wrap(Library.stop())
  end

  # small helper function to keep the chain going
  defp wrap(a, _), do: a

end
