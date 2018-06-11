defmodule Farmbot.Mixfile do
  use Mix.Project
  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join(__DIR__, "VERSION") |> File.read!() |> String.trim()

  defp commit do
    System.cmd("git", ~w"rev-parse --verify HEAD") |> elem(0) |> String.trim()
  end

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
      arduino_commit: arduino_commit(),
      archives: [nerves_bootstrap: "~> 1.0.0"],
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

  def application do
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

  defp make_env do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" =>
            Path.join([:code.root_dir(), "usr", "include"]),
          "ERL_EI_LIBDIR" => Path.join([:code.root_dir(), "usr", "lib"]),
          "MIX_TARGET" => @target
        }

      _ ->
        %{}
    end
  end

  defp deps do
    [
      {:nerves, "~> 1.0.1", runtime: false},
      {:elixir_make, "~> 0.4.1", runtime: false},
      {:gen_stage, "~> 0.12"},
      {:phoenix_html, "~> 2.10.5"},
      {:poison, "~> 3.1.0"},
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.1"},
      {:jsx, "~> 2.8.0"},
      {:timex, "~> 3.3"},
      {:fs, "~> 3.4.0"},
      {:nerves_uart, "~> 1.2"},
      {:nerves_leds, "~> 0.8.0"},
      {:cowboy, "~> 1.0.0"},
      {:plug, "~> 1.0"},
      {:cors_plug, "~> 1.5"},
      {:rsa, "~> 0.0.1"},
      {:joken, "~> 1.1"},
      {:ecto, "~> 2.2.2"},
      {:sqlite_ecto2, "~> 2.2.1"},
      {:uuid, "~> 1.1"},
      {:socket, "~> 0.3.13"},
      {:amqp, "~> 1.0"},
      {:recon, "~> 2.3.2"},
      {:ring_logger, "~> 0.4.1"},
      {:bbmustache, "~> 1.5"},
      {:apex, "~>1.2.0"}
    ]
  end

  defp deps("host") do
    [
      {:ex_doc, "~> 0.18.1", only: :dev},
      {:excoveralls, "~> 0.7", only: :test},
      {:dialyxir, github: "jeremyjh/dialyxir", only: :dev, runtime: false},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:inch_ex, ">= 0.0.0", only: :dev},
      {:mock, "~> 0.2.0", only: :test},
      {:faker, "~> 0.9", only: :test}
    ]
  end

  defp deps(target) do
    system(target) ++
      [
        {:shoehorn, "~> 0.2.0", except: :test},
        {:nerves_runtime, "0.5.3"},
        {:nerves_firmware, "~> 0.4.0"},
        {:nerves_init_gadget, "~> 0.3.0", only: :dev},
        {:nerves_network, "~> 0.3"},
        {:nerves_wpa_supplicant,
         github: "nerves-project/nerves_wpa_supplicant", override: true},
        {:dhcp_server, "~> 0.3.0"},
        {:elixir_ale, "~> 1.0"},
        {:mdns, "~> 1.0"}
      ]
  end

  defp system("rpi3"),
    do: [{:nerves_system_farmbot_rpi3, "1.0.1-farmbot.0", runtime: false}]

  defp system("rpi0"),
    do: [{:nerves_system_farmbot_rpi0, "1.0.0-rc.1-farmbot.0", runtime: false}]

  defp system("bbb"),
    do: [{:nerves_system_farmbot_bbb, "1.0.0-rc.1-farmbot.0", runtime: false}]

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
