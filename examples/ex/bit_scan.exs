defmodule Danm.Schematic.BitScan do

  use Bitwise
  import Danm.Schematic

  def doc_string(_) do 
    ~S"""
    I detect the first bit that is 1 after the location indicated by a thermometer code:
    111 -> 0
    110 -> 1
    100 -> 2.
    """
  end

  def build(s) do
    width = s.params["width"] || 8
    s
    |> create_port("in", width: width)
    |> create_port("last", width: width + 1)
    |> bind_to(s)

    case width do
      1 -> build_width_1(s)
      width -> build_width_n(s, width)
    end
    |> expose(["exist", "exist_right", "out"])
  end

  # degenerated case
  defp build_width_1(s) do
    s
    |> assign("in", as: "exist")
    |> assign("~last[1]&in", as: "exist_right")
    |> assign("in", as: "out")
  end

  defp build_width_n(s, width) do
    top_width = ceil(width/2)
    bottom_width = floor(width/2)
    top_mask = (1<<<top_width)-1
    bottom_mask = "#{bottom_width}d0"

    Enum.reduce([{"top", top_width}, {"bottom", bottom_width}], s,
      fn {i_name, w}, s ->
	s
	|> add("bit_scan", as: i_name,
	   parameters: %{"width" => w},
	   connections: %{
	     "in" => "#{i_name}_in",
	     "last" => "#{i_name}_last",
	     "out" => "#{i_name}_out",
	     "exist" => "#{i_name}_exist",
	     "exist_right" => "#{i_name}_exist_right" })
      end)
    |> assign("in[#{width-1}:#{bottom_width}]", as: "top_in")
    |> assign("in[#{bottom_width-1}:0]", as: "bottom_in")
    |> assign("last[#{width}:#{bottom_width}]", as: "top_last")
    |> assign("last[#{bottom_width}:0]", as: "bottom_last")
    |> assign("top_exist|bottom_exist", as: "exist")
    |> assign("top_exist_right|bottom_exist_right", as: "exist_right")
    |> condition([
       {"~top_exist&bottom_exist", top_mask},
       {"~top_exist_right&bottom_exist_right", top_mask},
       {1, "top_out"}], as: "top_out_masked")
    |> condition([
       {"top_exist_right", bottom_mask},
       {"~bottom_exist_right&top_exist", bottom_mask},
       {1, "bottom_out"}], as: "bottom_out_masked")
    |> assign("top_out_masked,bottom_out_masked", as: "out")
  end

end
