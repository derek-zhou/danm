defmodule Danm.RrArbiterTest do
  use ExUnit.Case
  import Danm

  setup do
    [sch: build("rr_scan_arbiter",
	verilog_path: ["examples/verilog"],
	elixir_path: ["examples/ex"],
	parameters: %{"width" => 16})]
  end

  test "check design", context do
    context[:sch] |> check_design(check_warnings: true) |> assert("check design failed")
  end

  test "html printing", context do
    context[:sch] |> generate_html_as_top(in: "obj") |> assert("html print failed")
  end

  test "verilog printing", context do
    context[:sch] |> generate_full_verilog(in: "obj") |> assert("verilog print failed")
  end

end
