defmodule Farmbot.Mixfile do
  use Mix.Project
  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join(__DIR__, "VERSION") |> File.read!() |> String.trim()

  defp commit do
    System.cmd("git", ~w"rev-parse --verify HEAD") |> elem(0) |> String.trim()
  end

  defp arduino_commit do
    opts = [cd: "c_src/farmbot-arduino-firmware"]
    System.cmd("git", ~w"rev-parse --verify HEAD", opts) |> elem(0) |> String.trim()
  end

  Mix.shell().info([
    :green,
    """
    Env
      MIX_TARGET:   #{@target}
      MIX_ENV:      #{Mix.env()}
    """,
    :reset
  ])

  def project do
    [
      app: :farmbot,
      description: "The Brains of the Farmbot Project",
      package: package(),
      compilers: compilers(),
      make_clean: ["clean"],
      test_coverage: [tool: ExCoveralls],
      version: @version,
      target: @target,
      commit: commit(),
      arduino_commit: arduino_commit(),
      archives: [nerves_bootstrap: "~> 0.7.0"],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",
      config_path: "config/config.exs",
      lockfile: "mix.lock",
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
    [mod: {Farmbot, []}, extra_applications: [:logger, :eex, :ssl, :inets, :runtime_tools]]
  end

  defp docs do
    [
      main: "Farmbot",
      logo: "priv/static/farmbot_logo.png",
      source_ref: commit(),
      extras: [
        "docs/BUILDING.md",
        "docs/FAQ.md",
        "README.md"
      ],
    ]
  end

  defp compilers do
    case :init.get_plain_arguments() |> List.last() do
      a when a in ['mix', 'compile', 'firmware'] ->
        [:elixir_make] ++ Mix.compilers
      _ -> Mix.compilers
    end
  end

  defp deps do
    [
      {:nerves, "~> 0.9.0", runtime: false},
      {:elixir_make, "~> 0.4", runtime: false},
      {:gen_stage, "~> 0.12"},

      {:poison, "~> 3.1.0"},
      {:httpoison, "~> 0.13.0"},
      {:jsx, "~> 2.8.0"},

      {:tzdata, "~> 0.5.14"},
      {:timex, "~> 3.1.13"},

      {:fs, "~> 3.4.0"},
      {:nerves_uart, "~> 1.0"},
      {:nerves_leds, "~> 0.8.0"},

      {:cowboy, "~> 1.1"},
      {:plug, "~> 1.4"},
      {:cors_plug, "~> 1.2"},
      {:wobserver, "~> 0.1.8"},
      {:rsa, "~> 0.0.1"},
      {:joken, "~> 1.1"},

      {:ecto, "~> 2.2.2"},
      {:sqlite_ecto2, "~> 2.2.1"},
      {:uuid, "~> 1.1"},

      {:socket, "~> 0.3"},
      {:amqp, "~> 1.0.0-pre.2"},

      {:recon, "~> 2.3"},
    ]
  end

  defp deps("host") do
    [
      {:ex_doc, "~> 0.18.1", only: :dev},
      {:excoveralls, "~> 0.7", only: :test},
      {:dialyxir, "~> 0.5.1", only: :dev, runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:inch_ex, ">= 0.0.0", only: :dev},
      {:mock, "~> 0.2.0", only: :test},
      {:faker, "~> 0.9", only: :test},
    ]
  end

  defp deps("rpi3") do
    system("rpi3") ++
      [
        {:shoehorn, "~> 0.2.0", except: :test},
        {:nerves_runtime, "0.5.3"},
        {:nerves_firmware, "~> 0.4.0"},
        {:nerves_firmware_ssh, "~> 0.2", only: :dev},
        {:nerves_network, "~> 0.3.6"},
        {:dhcp_server, "~> 0.3.0"},
        {:elixir_ale, "~> 1.0"}
      ]
  end

  defp deps(target) do
    system(target) ++
      [
        {:shoehorn, "~> 0.2.0", except: :test},
        {:nerves_runtime, "0.5.3"},
        {:nerves_firmware, "~> 0.4.0"},
        {:nerves_firmware_ssh, "~> 0.2", only: :dev},
        {:nerves_init_gadget,  github: "nerves-project/nerves_init_gadget", branch: "dhcp", only: :dev},
        {:nerves_network, "~> 0.3.5"},
        {:dhcp_server, "~> 0.3.0"},
        {:elixir_ale, "~> 1.0"},
      ]
  end

  defp system("rpi3"),
    do: [{:nerves_system_farmbot_rpi3, "0.20.0-farmbot", runtime: false}]

  defp system("rpi0"),
    do: [{:nerves_system_farmbot_rpi0, "0.20.0-farmbot", runtime: false}]

  defp system("bbb"),
    do: [{:nerves_system_farmbot_bbb, "0.19.0-farmbot", runtime: false}]

  defp package do
    [
      name: "farmbot",
      maintainers: ["Farmbot.io"],
      licenses: ["MIT"],
      links: %{"github" => "https://github.com/farmbot/farmbot_os"},
    ]
  end

  defp elixirc_paths(:test, "host") do
    ["./lib", "./nerves/host", "./test/support"]
  end

  defp elixirc_paths(_, "host") do
    ["./lib", "./nerves/host"]
  end

  defp elixirc_paths(_env, _target) do
    ["./lib", "./nerves/target"]
  end

  defp aliases(:test, "host") do
    ["test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end

  defp aliases(_env, "host"), do: [
    "firmware.slack": ["farmbot.firmware.slack"],
    "firmware.sign":  ["farmbot.firmware.sign"]
  ]

  defp aliases(_env, _system) do
    [
      "firmware.slack": ["farmbot.firmware.slack"],
      "firmware.sign":  ["farmbot.firmware.sign"],
      "deps.precompile": ["nerves.precompile", "deps.precompile"],
      "deps.loadpaths": ["deps.loadpaths", "nerves.loadpaths"]
    ] |> Nerves.Bootstrap.add_aliases()
  end
end
