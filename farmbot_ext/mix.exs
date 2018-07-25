defmodule Farmbot.Ext.MixProject do
  use Mix.Project
  @version Path.join([__DIR__, "..", "VERSION"]) |> File.read!() |> String.trim()
  @branch System.cmd("git", ~w"rev-parse --abbrev-ref HEAD") |> elem(0) |> String.trim()

  def project do
    [
      app: :farmbot_ext,
      version: @version,
      branch: @branch,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["lib", "vendor"],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Farmbot.Ext, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:farmbot_core, path: "../farmbot_core", env: Mix.env()},
      {:ranch_proxy_protocol, "~> 2.0", override: true},
      {:httpoison, "~> 1.2"},
      {:jason, "~> 1.1"},
      {:uuid, "~> 1.1"},
      {:amqp, "~> 1.0"},
      {:fs, "~> 3.4"},
    ]
  end
end
