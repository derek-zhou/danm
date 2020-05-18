defmodule Danm.Schematic.ScanArbiter do

  use Bitwise
  import Danm.Schematic

  def doc_string(_) do 
    ~S"""
    I am a round robin arbiter, that grant access according to request in a fair
    way by scanning forward. Unlike rr_arbiter, I am completely fair but bigger
    and slower
    """
  end

  def build(s) do
    width = s.params["width"] || 8
    s
    |> create_port("clk")
    |> create_port("reset_")
    |> create_port("busy")
    |> create_port("request", width: width)
    |> condition([
       {"~reset_",  0},
       {"busy",     0},
       {"|request", 1}], flop_by: "clk", as: "lag")
    |> bind_to(s)
    
    Enum.reduce(width-1..0, s, fn i, s ->
      s
      |> condition([
         {"~reset_",     0},
	 {"grant[#{i}]", 1},
	 {"~(busy|lag)", 0}], flop_by: "clk", as: "client#{i}_en")
    end)
    |> bundle(Enum.map(width-1..0, fn i -> "client#{i}_en" end), as: "client_en")
    |> bind_to(s)
    
    case width do
      1 -> s |> assign("(busy|lag)?0:request", as: "grant")
      width ->
	mask = (1<<<width)-1
	s
	|> add("bit_scan", as: "scanner",
	   parameters: %{"width" => width},
	   connections: %{
	     "in" => "request",
	     "out" => "next",
	     "last" => "scanner_last" })
	|> condition([
	   {"~reset_", mask},
	   {"~(busy|lag)&|request", "next"}], flop_by: "clk", as: "last")
	|> assign("last, 1b0", as: "scanner_last")
	|> assign("(busy|lag)?0:(next[#{width-1}:1]&~next[#{width-2}:0],next[0])", as: "grant")
	|> auto_connect()
	|> sink(["exist", "exist_right"])
    end
    |> expose(["grant", "client_en"])
  end

end
