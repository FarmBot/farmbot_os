defmodule UUID.Mixfile do
  use Mix.Project

  @version "1.1.8"

  def project do
    [app: :uuid,
     name: "UUID",
     version: @version,
     elixir: "~> 1.0",
     docs: [extras: ["README.md", "CHANGELOG.md"],
            main: "readme",
            source_ref: "v#{@version}"],
     source_url: "https://github.com/zyro/elixir-uuid",
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Application configuration.
  def application do
    []
  end

  # List of dependencies.
  defp deps do
    [{:ex_doc, "~> 0.16", only: :dev},
     {:earmark, "~> 1.2", only: :dev},
     {:benchfella, "~> 0.3", only: :dev}]
  end

  # Description.
  defp description do
    """
    UUID generator and utilities for Elixir.
    """
  end

  # Package info.
  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Andrei Mihu"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/zyro/elixir-uuid"}]
  end

end
