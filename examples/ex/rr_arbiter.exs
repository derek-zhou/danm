defmodule Danm.Schematic.RrArbiter do

  use Bitwise
  import Danm.Schematic

  def doc_string(_) do
    ~S"""
    I am a round robin arbiter, that grant access according to request.
    If you care about fairness, do not use me and use scan_arbiter instead.
    I am smaller and faster, but imprecise. I do not waste cycle and I will not
    starve anyone.
    """
  end

  def build(s) do
    width = s.params["width"] || 8
    s
    |> create_port("busy")
    |> create_port("request", width: width)
    |> bind_to(s)

    case width do
      1 -> build_width_1(s)
      n -> build_width_n(s, n)
    end
    |> expose(["exist", "grant"])
  end

  # degenerated case
  defp build_width_1(s) do
    s
    |> assign("request&~busy", as: "grant")
    |> assign("request", as: "exist")
  end

  defp build_width_n(s, width) do
    top_width = ceil(width/2)
    bottom_width = floor(width/2)

    Enum.reduce([{"top", top_width}, {"bottom", bottom_width}], s,
      fn {i_name, w}, s ->
	s
	|> add("rr_arbiter", as: i_name,
	   parameters: %{"width" => w},
	   connections: %{
	     "grant" => "#{i_name}_grant",
	     "request" => "#{i_name}_request",
	     "busy" => "#{i_name}_busy",
	     "exist" => "#{i_name}_exist" })
      end)
    |> create_port("clk")
    |> create_port("reset_")
    |> assign("request[#{width-1}:#{bottom_width}]", as: "top_request")
    |> assign("request[#{bottom_width-1}:0]", as: "bottom_request")
    |> assign("top_exist|bottom_exist", as: "exist")
    |> condition([
       {"~reset_", 0},
       {"~busy", "state?~bottom_exist:top_exist"}], flop_by: "clk", as: "state")
    |> assign("busy|(state&bottom_exist)", as: "top_busy")
    |> assign("busy|(~state&top_exist)", as: "bottom_busy")
    |> assign("top_grant, bottom_grant", as: "grant")
    |> auto_connect()
  end
  
end
