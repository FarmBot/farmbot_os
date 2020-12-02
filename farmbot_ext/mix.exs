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
      {:amqp, "~> 1.6.0"},
      {:ex_doc, "~> 0.23.0", only: [:dev], targets: [:host], runtime: false},
      {:excoveralls, "~> 0.13.3", only: [:test], targets: [:host]},
      {:extty, "~> 0.1"},
      {:farmbot_core, path: "../farmbot_core", env: Mix.env()},
      {:farmbot_telemetry, path: "../farmbot_telemetry", env: Mix.env()},
      {:hackney, "~> 1.16"},
      {:mimic, "~> 1.3.1", only: :test},
      {:tesla, "~> 1.3.3"},
      {:uuid, "~> 1.1.8"}
    ]
  end
end
