defmodule Farmbot.Mixfile do
  use Mix.Project

  def target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
  def target(_), do: System.get_env("NERVES_TARGET") || "development"

  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip
  @compat_version Path.join(__DIR__, "COMPAT") |> File.read! |> String.strip |> String.to_integer

  def project do
    [app: :farmbot,
     test_coverage: [tool: ExCoveralls],
     version: @version,
     target: target(Mix.env),
     archives: [nerves_bootstrap: "~> 0.2.0"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     build_path:  "../../_build/#{target(Mix.env)}",
     deps_path:   "../../deps/#{target(Mix.env)}",
     config_path: "../../config/config.exs",
     lockfile:    "../../mix.lock",
     aliases: aliases(Mix.env),
     deps: deps(Mix.env),
     name: "Farmbot",
     source_url: "https://github.com/Farmbot/farmbot_os",
     homepage_url: "http://farmbot.io",
     docs: [main: "farmbot", # The main page in the docs
            extras: ["README.md"]]
   ]
  end

  def application do
    [mod: {Farmbot, [%{target: target(Mix.env), compat_version: @compat_version,
                       version: @version, env: Mix.env}]},
     applications: apps(Mix.env),
     included_applications: [:gen_mqtt]]
  end

  # common for test, prod, and dev
  def apps do
    [:logger,
     :nerves_uart,
     :nerves_interim_wifi,
     :httpotion,
     :poison,
     :gen_stage,
     :nerves_lib,
     :rsa,
     :runtime_tools,
     :mustache,
     :timex,
     :farmbot_auth,
     :farmbot_configurator,
     :farmbot_filesystem,
     :vmq_commons,
     :amnesia,
     :quantum]
  end

  # on device
  def apps(:prod) do
    apps ++ platform_apps(target(:prod)) ++ [:nerves, :nerves_firmware_http]
  end

  # dev
  def apps(:dev), do: apps ++ []

  # test
  def apps(:test) do
    apps ++ [
      :plug,
      :cors_plug,
      :cowboy,
      :faker
    ]
  end

  def deps do
    [
      {:nerves_uart, "~> 0.1.0"},
      {:nerves_interim_wifi, "~> 0.1.0"},
      {:httpotion, "~> 3.0.0"},
      {:poison, "~> 3.0"},
      {:gen_stage, "~> 0.4"},
      {:nerves_lib, github: "nerves-project/nerves_lib"},
      {:gen_mqtt, "~> 0.3.1"},
      {:vmq_commons, "1.0.0", manager: :rebar3}, # This is for mqtt to work.
      {:mustache, "~> 0.0.2"},
      {:timex, "~> 3.0"},
      {:amnesia, github: "meh/amnesia"},
      {:quantum, ">= 1.8.1"},
      {:farmbot_configurator, in_umbrella: true},
      {:farmbot_auth, in_umbrella: true},
      {:farmbot_filesystem, in_umbrella: true}
    ]
  end

  def deps(:prod) do
    deps ++ platform_deps(target(Mix.env)) ++ system(target(Mix.env)) ++
    [
     {:nerves,  "~> 0.4.0"},
     {:nerves_firmware_http, github: "nerves-project/nerves_firmware_http"}
    ]
  end

  def deps(:test) do
    deps ++ deps(:dev) ++
    [ {:plug, "~> 1.0"},
      {:cors_plug, "~> 1.1"},
      {:cowboy, "~> 1.0.0"},
      {:excoveralls, "~> 0.5"},
      {:faker, "~> 0.7"} ]
  end

  def deps(:dev) do
    deps ++ [
      {:credo, "~> 0.4"},
      {:ex_doc, "~> 0.14", only: :dev},
      {:dialyxir, "~> 0.4"}]
  end

  def platform_deps("rpi3") do
    [
      {:nerves_leds, "~> 0.7.0"},
      {:elixir_ale, "~> 0.5.5"}
    ]
  end

  def platform_deps("qemu"), do: []

  def platform_apps("rpi3") do
    [ :nerves_leds,
      :elixir_ale ]
  end

  def platform_apps("qemu"), do: [:nerves_system_qemu_arm]

  def aliases(:prod) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

  def aliases(_), do: []

  def system(sys), do: [{:"nerves_system_#{sys}", in_umbrella: true}]
end
