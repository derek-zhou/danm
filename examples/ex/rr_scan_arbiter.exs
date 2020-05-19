defmodule Danm.Schematic.RrScanArbiter do

  use Bitwise
  import Danm.Schematic

  def doc_string(_) do
    ~S"""
    I wrap around a rr_arbiter to behave more like a scan arbiter
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
    |> assign("busy|lag", as: "long_busy")
    |> bind_to(s)

    Enum.reduce(width-1..0, s, fn i, s ->
      s
      |> condition([
         {"~reset_",     0},
	 {"grant[#{i}]", 1},
	 {"~long_busy", 0}], flop_by: "clk", as: "client#{i}_en")
    end)
    |> bundle(Enum.map(width-1..0, fn i -> "client#{i}_en" end), as: "client_en")
    |> add("rr_arbiter", as: "arb",
       parameters: %{"width" => width},
       connections: %{"busy" => "long_busy"})
    |> auto_connect()
    |> sink("exist")
    |> expose(["grant", "client_en"])
  end

end
