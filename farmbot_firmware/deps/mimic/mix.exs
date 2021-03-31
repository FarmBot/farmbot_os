defmodule Mimic.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mimic,
      version: "1.4.0",
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Mimic",
      description: "Mocks for Elixir functions",
      deps: deps(),
      package: package(),
      test_coverage: [tool: Mimic.TestCover],
      docs: [extras: ["README.md"], main: "readme"]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :tools],
      mod: {Mimic.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:credo, "~> 1.1.4", only: :dev}
    ]
  end

  defp package do
    %{
      files: ["lib", "LICENSE", "mix.exs", "README.md"],
      licenses: ["Apache 2"],
      maintainers: ["Eduardo Gurgel"],
      links: %{"GitHub" => "https://github.com/edgurgel/mimic"}
    }
  end
end
