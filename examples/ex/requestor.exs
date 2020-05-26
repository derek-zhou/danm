defmodule Danm.Schematic.Requestor do

  use Bitwise
  import Danm.Schematic

  def doc_string(_) do
    ~S"""
    I mock a client that generate requests
    """
  end

  def build(s) do
    s
    |> create_port("clk")
    |> create_port("reset_")
    |> create_port("grant")
    |> fsm([
       init:    [{"delay_done", :request}],
       request: [{"grant", :nap}],
       nap:     [{"delay_done", :busy}],
       busy:    [{"delay_done", :init}]],
       flop_by: "clk", reset_by: "~reset_", as: "state")
    |> assign_fsm("state", init: "init", request: "request", nap: "nap", busy: "busy") 
    |> condition([
       {"init", "4d5"},
       {"nap",  "4d3"},
       {"busy", "4d13"},
       {1, "4d0"}], as: "delays")
    |> assign("state", flop_by: "clk", as: "state_d")
    |> assign("state!=state_d", as: "state_changed")
    |> condition([
       {"~reset_", "4d0"},
       {"state_changed", "delays"},
       {"~delay_done", "counter-1"}], flop_by: "clk", as: "counter")
    |> assign("counter==4d0", as: "delay_done")
    |> expose(["request", "busy"])
  end

end
