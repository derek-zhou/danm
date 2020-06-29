defmodule Danm.HierDesignTest do
  use ExUnit.Case
  import Danm

  setup_all do
    File.mkdir_p!("obj")
  end

  setup do
    [sch: build("ram_wrapper",
	verilog_path: ["examples/verilog"],
	elixir_path: ["examples/ex"],
	parameters: %{"width" => 12})]
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
