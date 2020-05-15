defmodule Danm.BitScanTest do
  use ExUnit.Case
  import Danm

  setup_all do
    {:ok,
     [sch: build("bit_scan",
	 verilog_path: ["examples/verilog"],
	 elixir_path: ["examples/ex"],
	 parameters: %{"width" => 16})]}
    end

  test "check design", context do
    context[:sch] |> check_design(check_warnings: true) |> assert()
  end

  test "html printing", context do
    context[:sch] |> generate_html_as_top(in: "obj") |> assert()
  end

  test "verilog printing", context do
    context[:sch] |> generate_full_verilog(in: "obj") |> assert()
  end

end
