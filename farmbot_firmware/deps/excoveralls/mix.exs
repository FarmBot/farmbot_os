defmodule ExCoveralls.Mixfile do
  use Mix.Project

  @source_url "https://github.com/parroty/excoveralls"

  def project do
    [
      app: :excoveralls,
      version: "0.13.4",
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env:
        cli_env_for(:test, [
          "coveralls",
          "coveralls.detail",
          "coveralls.html",
          "coveralls.json",
          "coveralls.post"
        ])
    ]
  end

  defp cli_env_for(env, tasks) do
    Enum.reduce(tasks, [], fn key, acc -> Keyword.put(acc, :"#{key}", env) end)
  end

  def application do
    [extra_applications: [:eex, :tools]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/fixtures/test_missing.ex"]
  defp elixirc_paths(_), do: ["lib"]

  def deps do
    [
      {:jason, "~> 1.0"},
      {:hackney, "~> 1.16"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:meck, "~> 0.8", only: :test},
      {:mock, "~> 0.3.6", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      assets: "assets",
      extras: ["README.md", "CHANGELOG.md": [title: "Changelog"]]
    ]
  end

  defp description do
    """
    Coverage report tool for Elixir with coveralls.io integration.
    """
  end

  defp package do
    [
      maintainers: ["parroty"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => @source_url <> "/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end
end
