import Config

config :danm,
  verilog_path: ["examples/verilog"],
  elixir_path: ["examples/ex"],
  output_dir: "obj",
  check_warning: true,
  default_params: %{
    "mock_system" => %{
      "client_count" => 8
      }
  }
