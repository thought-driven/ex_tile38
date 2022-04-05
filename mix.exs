defmodule Tile38.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_tile38,
      version: "0.4.0",
      elixir: "~> 1.11",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Elixir wrapper for Tile38 client. Formats responses to common queries for convenience.",
      package: package()
    ]
  end

  defp package do
    [
      maintainers: ["lpender"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/lunchtime-labs/ex_tile38"}
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
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:jason, "~> 1.0"},
      {:redix, ">= 0.0.0"}
    ]
  end
end
