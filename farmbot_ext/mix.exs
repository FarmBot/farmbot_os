defmodule FarmbotExt.MixProject do
  use Mix.Project
  @version Path.join([__DIR__, "..", "VERSION"]) |> File.read!() |> String.trim()
  @elixir_version Path.join([__DIR__, "..", "ELIXIR_VERSION"]) |> File.read!() |> String.trim()

  def project do
    [
      app: :farmbot_ext,
      version: @version,
      elixir: @elixir_version,
      elixirc_options: [warnings_as_errors: true, ignore_module_conflict: true],
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["lib", "vendor"],
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      source_url: "https://github.com/Farmbot/farmbot_os",
      homepage_url: "http://farmbot.io",
      docs: [
        logo: "../farmbot_os/priv/static/farmbot_logo.png",
        extras: Path.wildcard("../docs/**/*.md")
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {FarmbotExt, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:farmbot_core, path: "../farmbot_core", env: Mix.env()},
      {:farmbot_telemetry, path: "../farmbot_telemetry", env: Mix.env()},
      {:tesla, "~> 1.2"},
      {:hackney, "~> 1.15"},
      {:uuid, "~> 1.1"},
      {:amqp, "~> 1.4.0"},
      {:mimic, "~> 1.1", only: :test},
      {:excoveralls, "~> 0.10", only: [:test], targets: [:host]},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], targets: [:host], runtime: false},
      {:ex_doc, "~> 0.21.2", only: [:dev], targets: [:host], runtime: false}
    ]
  end
end
