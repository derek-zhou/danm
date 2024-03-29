defmodule Danm.MixProject do
  use Mix.Project

  def project do
    [
      app: :danm,
      version: "0.2.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      releases: [default: default_release()],
      # Docs
      name: "Danm",
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:html_writer, "~> 0.2.0"},
      # {:html_writer, path: "../html_writer"},
      {:ex_doc, "~> 0.28.4", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp description do
    "DANM, short for Design Automation aNd Manipulation, is a tool written by Derek for use in synthesizable RTL design."
  end

  defp package do
    [
      licenses: ["GPL-3.0-or-later"],
      links: %{"GitHub" => "https://github.com/derek-zhou/danm"}
    ]
  end

  defp default_release do
    [
      {:include_erts, true}
    ]
  end
end
