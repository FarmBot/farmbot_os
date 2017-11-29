defmodule Farmbot.Mixfile do
  use Mix.Project
  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join(__DIR__, "VERSION") |> File.read!() |> String.trim()

  defp commit() do
    {t, _} = System.cmd("git", ["log", "--pretty=format:%h", "-1"])
    t
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
      test_coverage: [tool: ExCoveralls],
      version: @version,
      target: @target,
      commit: commit(),
      archives: [nerves_bootstrap: "~> 0.6.0"],
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
        flags: []
      ],
      preferred_cli_env: [
        test: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test
      ],
      source_url: "https://github.com/Farmbot/farmbot_os",
      homepage_url: "http://farmbot.io",
      docs: docs()
    ]
  end

  def application do
    [mod: {Farmbot, []}, extra_applications: [:logger, :eex, :ssl, :inets]]
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
      # groups_for_modules: generate_doc_mods()
    ]
  end

  defp deps do
    [
      {:nerves, "~> 0.8.3", runtime: false},
      {:vmq_commons_fb, "~> 1.0.2"},
      {:gen_stage, "~> 0.12"},
      {:poison, "~> 3.0"},
      {:ex_json_schema, "~> 0.5.3"},
      {:rsa, "~> 0.0.1"},
      {:httpoison, "~> 0.13.0"},
      {:tzdata, "~> 0.5.14"},
      {:timex, "~> 3.1.13"},

      {:fs, "~> 3.4.0"},
      {:nerves_uart, "0.1.2"},
      {:uuid, "~> 1.1"},
      {:cowboy, "~> 1.1"},
      {:plug, "~> 1.4"},
      {:cors_plug, "~> 1.2"},
      {:ecto, "~> 2.2.2"},
      {:sqlite_ecto2, "~> 2.2.1"},
      {:wobserver, "~> 0.1.8"},
      {:joken, "~> 1.1"},
      {:socket, "~> 0.3"},
      {:amqp, "~> 1.0.0-pre.2"},
      {:nerves_ssdp_server, "~> 0.2.2", only: :dev},
      {:nerves_ssdp_client, "~> 0.1.0", only: :dev},

      {:ex_syslogger, "~> 1.4", only: :prod}
    ]
  end

  defp deps("host") do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.17", only: :dev},
      {:inch_ex, ">= 0.0.0", only: :dev},
      {:excoveralls, "~> 0.6", only: :test},
      {:mock, "~> 0.2.0", only: :test},
      {:faker, "~> 0.9", only: :test },
      {:udev, github: "electricshaman/udev"}
    ]
  end

  defp deps(target) do
    system(target) ++
      [
        {:bootloader, "~> 0.1"},
        {:nerves_runtime, "~> 0.4"},
        {:nerves_firmware, "~> 0.4.0"},
        {:nerves_firmware_ssh, "~> 0.2"},
        {:nerves_network, "~> 0.3", github: "nerves-project/nerves_network", override: true},
        {:dhcp_server, github: "nerves-project/dhcp_server", branch: "elixirize-go!", override: true},
        {:elixie_ale, ">= 0.0"}
        # {:nerves_init_gadget, github: "nerves-project/nerves_init_gadget", branch: "dhcp", only: :dev},
      ]
  end

  defp system("rpi3"),
    do: [{:nerves_system_farmbot_rpi3, "0.17.2-farmbot.1", runtime: false}]

  defp system("rpi0"),
    do: [{:nerves_system_farmbot_rpi0, "0.18.3-farmbot", runtime: false}]

  defp system("bbb"),
    do: [{:nerves_system_farmbot_bbb, "0.17.2-farmbot", runtime: false}]

  defp package do
    [
      name: "farmbot",
      maintainers: ["Farmbot.io"],
      licenses: ["MIT"],
      links: %{"github" => "https://github.com/farmbot/farmbot_os"},
    ]
  end

  defp elixirc_paths(:dev, "host") do
    ["./lib", "./nerves/host"]
  end

  defp elixirc_paths(:test, "host") do
    ["./lib", "./nerves/host", "./test/support"]
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
    ]
  end
end
