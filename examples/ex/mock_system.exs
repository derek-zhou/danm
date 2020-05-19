defmodule Danm.Schematic.MockSystem do

  use Bitwise
  import Danm.Schematic

  def build(s) do
    client_count = s.params["client_count"] || 8
    s
    |> create_port("clk")
    |> create_port("reset_")
    |> add("scan_arbiter", as: "arbiter",
       parameters: %{"width" => client_count})
    |> add("collision_detector", as: "u_cd",
       parameters: %{"width" => client_count})
    |> connect(["arbiter/client_en", "u_cd/in"])
    |> bind_to(s)

    Enum.reduce(0..client_count-1, s, fn i, s ->
      s
      |> assign("grant[#{i}]", as: "grant_#{i}")
      |> add("requestor", as: "req_#{i}",
         connections: %{
	   "request"=> "request_#{i}",
	   "grant"=> "grant_#{i}",
	   "busy"=> "busy_#{i}"})
    end)
    |> bundle(Enum.map(client_count-1..0, fn i -> "request_#{i}" end), as: "request")
    |> bundle(Enum.map(client_count-1..0, fn i -> "busy_#{i}" end), with: :or, as: "busy")
    |> auto_connect()
  end

end
