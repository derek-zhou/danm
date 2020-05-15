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
    top_mask = (1<<<ceil(width/2))-1
    bottom_mask = "#{floor(width/2)}d0"
    s =
      s
      |> create_port("in", width: width)
      |> create_port("last", width: width + 1)

    s =
      case width do
	# degenerated case
	1 ->
	  s
	  |> assign("in", as: "exist")
	  |> assign("~last[1]&in", as: "exist_right")
	  |> assign("in", as: "out")
	_ ->
	  s
	  |> add("bit_scan", as: "top", parameters: %{"width" => ceil(width / 2)}) 
	  |> add("bit_scan", as: "bottom", parameters: %{"width" => floor(width / 2)})
	  |> connect("top/in", as: "top_in") 
	  |> connect("top/last", as: "top_last") 
	  |> connect("top/out", as: "top_out") 
	  |> connect("top/exist", as: "top_exist") 
	  |> connect("top/exist_right", as: "top_exist_right") 
	  |> connect("bottom/in", as: "bottom_in") 
	  |> connect("bottom/last", as: "bottom_last") 
	  |> connect("bottom/out", as: "bottom_out") 
	  |> connect("bottom/exist", as: "bottom_exist") 
	  |> connect("bottom/exist_right", as: "bottom_exist_right") 
	  |> assign("in[#{width-1}:#{floor(width/2)}]", as: "top_in")
	  |> assign("in[#{floor(width/2)-1}:0]", as: "bottom_in")
	  |> assign("last[#{width}:#{floor(width/2)}]", as: "top_last")
	  |> assign("last[#{floor(width/2)}:0]", as: "bottom_last")
	  |> assign("top_exist|bottom_exist", as: "exist")
	  |> assign("top_exist_right|bottom_exist_right", as: "exist_right")
	  |> condition([{"~top_exist_right&bottom_exist_right", top_mask},
			{"~top_exist&bottom_exist", top_mask},
			{1, "top_out"}], as: "top_out_masked")
	  |> condition([{"~bottom_exist_right&top_exist", bottom_mask},
			{"top_exist_right", bottom_mask},
			{1, "bottom_out"}], as: "bottom_out_masked")
	  |> assign("top_out_masked,bottom_out_masked", as: "out")
      end
    s
    |> expose(["exist", "exist_right", "out"])

  end

end
