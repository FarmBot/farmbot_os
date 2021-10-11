defmodule FarmbotCore.MixProject do
  use Mix.Project
  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join([__DIR__, "..", "VERSION"])
           |> File.read!()
           |> String.trim()
  @branch System.cmd("git", ~w"rev-parse --abbrev-ref HEAD")
          |> elem(0)
          |> String.trim()
  @elixir_version Path.join([__DIR__, "..", "ELIXIR_VERSION"])
                  |> File.read!()
                  |> String.trim()

  defp commit do
    System.cmd("git", ~w"rev-parse --verify HEAD") |> elem(0) |> String.trim()
  end

  def project do
    [
      aliases: aliases(),
      app: :farmbot_core,
      branch: @branch,
      build_embedded: false,
      commit: commit(),
      compilers: Mix.compilers(),
      deps: deps(),
      description: "The Brains of the Farmbot Project",
      docs: [
        logo: "../farmbot_os/priv/static/farmbot_logo.png",
        extras: Path.wildcard("../docs/**/*.md")
      ],
      elixir: @elixir_version,
      elixirc_options: [warnings_as_errors: true, ignore_module_conflict: true],
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: "http://farmbot.io",
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      source_url: "https://github.com/Farmbot/farmbot_os",
      start_permanent: Mix.env() == :prod,
      target: @target,
      test_coverage: [tool: ExCoveralls],
      version: @version
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :runtime_tools, :ssh],
      mod: {FarmbotCore, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_uart, "~> 1.4"},
      {:ex_doc, "~> 0.25", only: [:dev], targets: [:host], runtime: false},
      {:excoveralls, "~> 0.14", only: [:test], targets: [:host]},
      {:extty, "~> 0.2.1"},
      {:farmbot_telemetry, path: "../farmbot_telemetry", env: Mix.env()},
      {:hackney, "~> 1.18"},
      {:jason, "~> 1.2"},
      {:mimic, "~> 1.5", only: :test},
      {:muontrap, "~> 0.6"},
      {:nerves_time, "~> 0.4.3", targets: [:rpi, :rpi3]},
      {:ecto, "~> 3.7"},
      {:ecto_sqlite3, "~> 0.7.1"},
      {:tesla, "~> 1.4.3"},
      {:timex, "~> 3.7"},
      {:tortoise, "~> 0.10"},
      {:uuid, "~> 1.1.8"}
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", Path.expand("../test/support")]
  end

  defp elixirc_paths(:dev) do
    ["lib", Path.expand("../test/support")]
  end

  defp elixirc_paths(_), do: ["lib"]

  defp aliases,
    do: [
      test: [
        "ecto.drop",
        "ecto.migrate",
        "test"
      ]
    ]
end
