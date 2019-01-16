defmodule Farmbot.Mixfile do
  use Mix.Project
  @target System.get_env("MIX_TARGET") || "host"
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
      elixir: "~> 1.6",
      package: package(),
      make_clean: ["clean"],
      make_env: make_env(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      test_coverage: [tool: ExCoveralls],
      version: @version,
      target: @target,
      commit: commit(),
      branch: branch(),
      arduino_commit: arduino_commit(),
      archives: [nerves_bootstrap: "~> 1.2"],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",
      config_path: "config/config.exs",
      elixirc_paths: elixirc_paths(Mix.env(), @target),
      aliases: aliases(Mix.env(), @target),
      deps: deps() ++ deps(@target),
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

  def application("host") do
    [
      mod: {Farmbot, []},
      extra_applications: [:logger, :eex, :ssl, :inets, :runtime_tools]
    ]
  end

  def application(_target) do
    [
      mod: {Farmbot, []},
      extra_applications: [:logger, :eex, :ssl, :inets, :runtime_tools],
      included_applications: [:nerves_hub]
    ]
  end

  def application(), do: application(@target)

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

  defp make_env do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => Path.join([:code.root_dir(), "usr", "include"]),
          "ERL_EI_LIBDIR" => Path.join([:code.root_dir(), "usr", "lib"]),
          "MIX_TARGET" => @target
        }

      _ ->
        %{}
    end
  end

  defp deps do
    [
      {:nerves, "~> 1.3", runtime: false},
      {:nerves_hub_cli, "~> 0.5", runtime: false},
      {:elixir_make, "~> 0.4", runtime: false},
      {:shoehorn, "~> 0.4"},
      {:gen_stage, "~> 0.14"},
      {:phoenix_html, "~> 2.12"},
      {:httpoison, "~> 1.3"},
      {:poison, "~> 3.1.0"},
      {:jason, "~> 1.1"},
      {:timex, "~> 3.4"},
      {:fs, "~> 3.4"},
      {:nerves_uart, "~> 1.2"},
      {:cowboy, "~> 2.5"},
      {:plug, "~> 1.6"},
      {:cors_plug, "~> 1.5"},
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
      {:logger_backend_sqlite, "~> 2.1"}
    ]
  end

  defp deps("host") do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:excoveralls, "~> 0.10", only: :test},
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false},
      {:credo, "~> 0.10", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3", only: :test},
      {:faker, "~> 0.11", only: :test}
    ]
  end

  defp deps(target) do
    system(target) ++
      [
        {:nerves_runtime, "~> 0.8"},
        {:nerves_hub, "~> 0.2.0"},
        {:nerves_firmware, "~> 0.4"},
        {:nerves_firmware_ssh, "~> 0.3"},
        {:nerves_init_gadget, "~> 0.5", only: :dev},
        {:nerves_time, "~> 0.2"},
        {:nerves_network, "~> 0.5"},
        # {:nerves_wpa_supplicant, "~> 0.5"},
        {:nerves_wpa_supplicant,
         github: "nerves-project/nerves_wpa_supplicant", branch: "eap-notifs", override: true},
        {:dhcp_server, "~> 0.6"},
        {:elixir_ale, "~> 1.1"},
        {:mdns, "~> 1.0"}
      ]
  end

  defp system("rpi3"),
    do: [{:farmbot_system_rpi3, "1.6.1-farmbot.0", runtime: false}]

  defp system("rpi0"),
    do: [{:farmbot_system_rpi0, "1.6.1-farmbot.0", runtime: false}]

  defp system("rpi"),
    do: [{:farmbot_system_rpi, "1.6.1-farmbot.0", runtime: false}]

  defp package do
    [
      name: "farmbot",
      maintainers: ["Farmbot.io"],
      licenses: ["MIT"],
      links: %{"github" => "https://github.com/farmbot/farmbot_os"}
    ]
  end

  defp elixirc_paths(:test, "host") do
    ["./lib", "./platform/host", "./test/support"]
  end

  defp elixirc_paths(_, "host") do
    ["./lib", "./platform/host"]
  end

  defp elixirc_paths(_env, _target) do
    ["./lib", "./platform/target"]
  end

  defp aliases(:test, "host") do
    [test: ["ecto.drop", "ecto.create --quiet", "ecto.migrate", "test"]]
  end

  defp aliases(_env, "host"),
    do: [
      "firmware.slack": ["farmbot.firmware.slack"],
      "firmware.sign": ["farmbot.firmware.sign"]
    ]

  defp aliases(_env, _system) do
    [
      "firmware.slack": ["farmbot.firmware.slack"],
      "firmware.sign": ["farmbot.firmware.sign"],
      loadconfig: [&bootstrap/1]
    ]
  end

  defp bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end
end
