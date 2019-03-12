defmodule Farmbot.Mixfile do
  use Mix.Project
  @all_targets [:rpi0, :rpi3, :rpi]

  @version Path.join(__DIR__, "VERSION") |> File.read!() |> String.trim()
  @commit System.cmd("git", ~w"rev-parse --verify HEAD") |> elem(0) |> String.trim()
  @branch System.cmd("git", ~w"rev-parse --abbrev-ref HEAD") |> elem(0) |> String.trim()
  System.put_env("NERVES_FW_VCS_IDENTIFIER", @commit)
  System.put_env("NERVES_FW_MISC", @branch)

  defp commit, do: @commit

  defp branch, do: @branch

  defp arduino_commit do
    opts = [cd: "c_src/farmbot-arduino-firmware"]

    System.cmd("git", ~w"rev-parse --verify HEAD", opts)
    |> elem(0)
    |> String.trim()
  end

  def project do
    [
      app: :farmbot,
      description: "The Brains of the Farmbot Project",
      elixir: "~> 1.8",
      package: package(),
      make_clean: ["clean"],
      compilers: [:elixir_make | Mix.compilers()],
      test_coverage: [tool: ExCoveralls],
      version: @version,
      commit: commit(),
      branch: branch(),
      arduino_commit: arduino_commit(),
      archives: [nerves_bootstrap: "~> 1.2"],
      build_embedded: false,
      start_permanent: Mix.env() == :prod,
      config_path: "config/config.exs",
      elixirc_paths: elixirc_paths(Mix.env(), Mix.target()),
      aliases: aliases(Mix.env(), Mix.target()),
      deps: deps(),
      dialyzer: [
        plt_add_deps: :transitive,
        plt_add_apps: [:mix],
        flags: []
      ],
      preferred_cli_env: [
        test: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.circle": :test
      ],
      source_url: "https://github.com/Farmbot/farmbot_os",
      homepage_url: "http://farmbot.io",
      docs: docs()
    ]
  end

  def application() do
    [
      mod: {Farmbot, []},
      extra_applications: [:logger, :eex, :ssl, :inets, :runtime_tools]
    ]
  end

  defp docs do
    [
      main: "building",
      logo: "priv/static/farmbot_logo.png",
      source_ref: commit(),
      extras: [
        "docs/BUILDING.md",
        "docs/FAQ.md",
        "README.md",
        "CHANGELOG.md",
        "CONTRIBUTING.md"
      ]
    ]
  end

  defp deps do
    [
      # Common deps
      {:nerves, "~> 1.3", runtime: false},
      {:nerves_hub_cli, "~> 0.5.1", runtime: false},
      {:elixir_make, "~> 0.5", runtime: false},
      {:shoehorn, "~> 0.4"},
      {:gen_stage, "~> 0.14"},
      {:phoenix_html, "~> 2.12"},
      {:httpoison, "~> 1.3"},
      {:poison, "~> 3.1.0"},
      {:jason, "~> 1.1"},
      {:timex, "~> 3.4"},
      {:fs, "~> 3.4"},
      {:circuits_uart, "~> 1.3"},
      {:plug_cowboy, "~> 2.0"},
      {:cors_plug, "~> 2.0"},
      {:amqp, "~> 1.0"},
      # AMQP hacks
      {:jsx, "~> 2.9", override: true},
      {:ranch, "~> 1.6", override: true},
      {:ranch_proxy_protocol, "~> 2.1", override: true},
      # End hacks
      {:rsa, "~> 0.0.1"},
      {:joken, "~> 1.5"},
      {:uuid, "~> 1.1"},
      {:ring_logger, "~> 0.5"},
      {:bbmustache, "~> 1.6"},
      {:sqlite_ecto2, "~> 2.2"},
      {:logger_backend_sqlite, "~> 2.1"},

      # Host only deps
      {:ex_doc, "~> 0.19", only: :dev, targets: :host},
      {:excoveralls, "~> 0.10", only: :test, targets: :host},
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false, targets: :host},
      {:credo, "~> 0.10", only: [:dev, :test], runtime: false, targets: :host},
      {:mock, "~> 0.3", only: :test, targets: :host},
      {:faker, "~> 0.11", only: :test, targets: :host},

      # Target Deps
      {:nerves_runtime, "~> 0.8", targets: @all_targets},
      {:nerves_hub, "~> 0.2.0", targets: @all_targets},
      {:nerves_firmware, "~> 0.4", targets: @all_targets},
      {:nerves_firmware_ssh, "~> 0.3", targets: @all_targets},
      {:nerves_init_gadget, "~> 0.5", only: :dev, targets: @all_targets},
      {:nerves_time, "~> 0.2", targets: @all_targets},
      {:nerves_network, "~> 0.5", targets: @all_targets},
      {:nerves_wpa_supplicant, "~> 0.5.1", targets: @all_targets},
      {:dhcp_server, "~> 0.7", targets: @all_targets},
      {:circuits_gpio, "~> 0.4.0", targets: @all_targets},
      {:mdns, "~> 1.0", targets: @all_targets},
      {:farmbot_system_rpi3, "1.6.3-farmbot.0", runtime: false, targets: :rpi3},
      {:farmbot_system_rpi0, "1.6.3-farmbot.0", runtime: false, targets: :rpi0},
      {:farmbot_system_rpi, "1.6.3-farmbot.0", runtime: false, targets: :rpi}
    ]
  end

  defp package do
    [
      name: "farmbot",
      licenses: ["MIT"],
      links: %{"github" => "https://github.com/farmbot/farmbot_os"}
    ]
  end

  defp elixirc_paths(:test, :host) do
    ["./lib", "./platform/host", "./test/support"]
  end

  defp elixirc_paths(_, :host) do
    ["./lib", "./platform/host"]
  end

  defp elixirc_paths(_env, _target) do
    ["./lib", "./platform/target"]
  end

  defp aliases(:test, :host) do
    [test: ["ecto.drop", "ecto.create --quiet", "ecto.migrate", "test"]]
  end

  defp aliases(_env, :host),
    do: []

  defp aliases(_env, _system) do
    [
      loadconfig: [&bootstrap/1]
    ]
  end

  defp bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end
end
