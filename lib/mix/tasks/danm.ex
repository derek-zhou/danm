defmodule Mix.Tasks.Danm do
  @moduledoc """
  build, check design, generate html and verilog for all top_modules specified in:
  config :danm top_modules
  """

  use Mix.Task

  @impl true
  def run(_args) do
    names =
      case Application.fetch_env(:danm, :top_modules) do
	{:ok, names} -> names
	_ -> raise("top_modules not found in config")
      end

    Mix.Task.run("app.start", [])
    Danm.auto_build(names)
  end

end
