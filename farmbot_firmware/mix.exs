defmodule FarmbotFirmware.MixProject do
  use Mix.Project

  @version Path.join([__DIR__, "..", "VERSION"])
           |> File.read!()
           |> String.trim()
  @elixir_version Path.join([__DIR__, "..", "ELIXIR_VERSION"])
                  |> File.read!()
                  |> String.trim()

  defp arduino_commit do
    opts = [cd: Path.join("c_src", "farmbot-arduino-firmware")]

    System.cmd("git", ~w"rev-parse --verify HEAD", opts)
    |> elem(0)
    |> String.trim()
  end

  def project do
    [
      app: :farmbot_firmware,
      version: @version,
      elixir: @elixir_version,
      elixirc_options: [warnings_as_errors: true, ignore_module_conflict: true],
      arduino_commit: arduino_commit(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        test: :test,
        coveralls: :test,
        "coveralls.circle": :test,
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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:farmbot_telemetry, path: "../farmbot_telemetry", env: Mix.env()},
      {:circuits_uart, "~> 1.4.0"},
      {:excoveralls, "~> 0.10", only: [:test], targets: [:host]},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], targets: [:host], runtime: false},
      {:mimic, "~> 1.1", only: :test},
      {:ex_doc, "~> 0.21.2", only: [:dev], targets: [:host], runtime: false}
    ]
  end
end
