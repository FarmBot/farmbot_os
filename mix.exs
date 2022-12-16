defmodule FarmbotOS.MixProject do
  use Mix.Project

  @all_targets [:rpi4, :rpi3, :rpi]
  @version Path.join([__DIR__, "VERSION"])
           |> File.read!()
           |> String.trim()
  @branch System.cmd("git", ~w"rev-parse --abbrev-ref HEAD")
          |> elem(0)
          |> String.trim()
  @commit System.cmd("git", ~w"rev-parse --verify HEAD")
          |> elem(0)
          |> String.trim()
  System.put_env("NERVES_FW_VCS_IDENTIFIER", @commit)
  System.put_env("NERVES_FW_MISC", @branch)

  @elixir_version Path.join([__DIR__, "ELIXIR_VERSION"])
                  |> File.read!()
                  |> String.trim()

  System.put_env("NERVES_FW_VCS_IDENTIFIER", @commit)

  def project do
    [
      aliases: aliases(),
      app: :farmbot,
      archives: [nerves_bootstrap: "~> 1.11"],
      branch: @branch,
      build_embedded: false,
      build_path: "_build/#{Mix.target()}",
      commit: @commit,
      compilers: Mix.compilers(),
      deps_path: "deps/#{Mix.target()}",
      deps: deps(),
      description: "The Brains of the Farmbot Project",
      docs: [
        logo: "../farmbot_os/priv/static/farmbot_logo.png",
        extras: Path.wildcard("../docs/**/*.md")
      ],
      elixir: @elixir_version,
      # elixirc_options: [warnings_as_errors: true], # TODO: deps have warnings
      elixirc_paths: elixirc_paths(Mix.env(), Mix.target()),
      homepage_url: "http://farmbot.io",
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      preferred_cli_target: [run: :host, test: :host],
      releases: [{:farmbot, release()}],
      source_url: "https://github.com/Farmbot/farmbot_os",
      start_permanent: Mix.env() == :prod,
      target: Mix.target(),
      test_coverage: [tool: ExCoveralls],
      version: @version
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "democookie",
      include_erts: &Nerves.Release.erts/0,
      strip_beams: false,
      steps: [&Nerves.Release.init/1, :assemble]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {FarmbotOS, []},
      extra_applications: [
        :certifi,
        :crypto,
        :eex,
        :inets,
        :logger,
        :public_key,
        :rollbax,
        :runtime_tools,
        :ssh
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:busybox, "~> 0.1", targets: @all_targets},
      {:certifi, "~> 2.9"},
      {:circuits_gpio, "~> 1.0", targets: @all_targets},
      {:circuits_i2c, "~> 1.1", targets: @all_targets},
      {:circuits_uart, "~> 1.5"},
      {:cors_plug, "~> 3.0", targets: @all_targets},
      {:dns, "~> 2.4"},
      {:ecto_sqlite3, "~> 0.9"},
      {:ecto, "~> 3.9"},
      {:ex_doc, "~> 0.29", only: [:dev], targets: [:host], runtime: false},
      {:excoveralls, "~> 0.15", only: [:test], targets: [:host]},
      {:farmbot_system_rpi,
       git: "git@github.com:FarmBot/farmbot_system_rpi.git",
       tag: "v1.21.1-farmbot.1",
       runtime: false,
       targets: :rpi},
      {:farmbot_system_rpi3,
       git: "git@github.com:FarmBot/farmbot_system_rpi3.git",
       tag: "v1.21.1-farmbot.1",
       runtime: false,
       targets: :rpi3},
      {:farmbot_system_rpi4,
       git: "git@github.com:FarmBot/farmbot_system_rpi4.git",
       tag: "v1.21.1-farmbot.1",
       runtime: false,
       targets: :rpi4},
      {:extty, "~> 0.2"},
      {:hackney, "~> 1.18"},
      {:jason, "~> 1.4"},
      {:luerl, "~> 1.0"},
      {:mdns_lite, "~> 0.8", targets: @all_targets},
      {:mimic, "~> 1.7", only: :test},
      {:mix_unused, "~> 0.4", only: :dev},
      {:muontrap, "~> 1.1"},
      {:nerves_runtime, "~> 0.13", targets: @all_targets},
      {:nerves_time, "~> 0.4", targets: @all_targets},
      {:nerves, "~> 1.9", runtime: false},
      {:phoenix_html, "~> 3.2"},
      {:plug_cowboy, "~> 2.6"},
      {:ring_logger, "~> 0.8"},
      {:rollbax, "~> 0.11"},
      {:shoehorn, "~> 0.8"},
      {:telemetry, "~> 1.1"},
      {:tesla, "~> 1.5"},
      {:timex, "~> 3.7"},
      {:toolshed, "~> 0.2", targets: @all_targets},
      {:tortoise, "~> 0.10"},
      {:uuid, "~> 1.1"},
      {:vintage_net_ethernet, "~> 0.11", targets: @all_targets},
      {:vintage_net_wifi, "~> 0.11", targets: @all_targets},
      {:vintage_net, "~> 0.12", targets: @all_targets}
    ]
  end

  defp elixirc_paths(:test, _) do
    ["./lib", "./platform/host", "./test"]
  end

  defp elixirc_paths(_, :host) do
    ["./lib", "./platform/host"]
  end

  defp elixirc_paths(_env, _target) do
    ["./lib", "./platform/target"]
  end

  def aliases do
    [
      loadconfig: [&bootstrap/1],
      test: [
        "ecto.drop",
        "ecto.migrate",
        "test"
      ]
    ]
  end
end
