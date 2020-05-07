defmodule Danm do
  @moduledoc """
  Public API for `Danm`.
  """

  alias Danm.Library
  alias Danm.Schematic
  alias Danm.BlackBox

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
    |> Schematic.elaborate()
    |> wrap(Library.stop())
  end

  # small helper function to keep the chain going
  defp wrap(a, _) do
    a
  end

end
