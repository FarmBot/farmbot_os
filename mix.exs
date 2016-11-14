defmodule Fw.Mixfile do
  Code.load_file("tasks.exs")

  use Mix.Project

  def target(:prod) do
    System.get_env("NERVES_TARGET") || "rpi3"
  end

  def target(_) do
    System.get_env("NERVES_TARGET") || "development"
  end

  @version Path.join(__DIR__, "VERSION")
    |> File.read!
    |> String.strip

  @compat_version Path.join(__DIR__, "COMPAT")
    |> File.read!
    |> String.strip
    |> String.to_integer

  def project do
    [app: :fw,
     version: @version,
     target: target(Mix.env),
     archives: [nerves_bootstrap: "~> 0.1.4"],
     deps_path: "deps/#{target(Mix.env)}",
     build_path: "_build/#{target(Mix.env)}",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     config_path: "config/config.exs",
     aliases: aliases(Mix.env),
     deps: deps(Mix.env) ]
  end

  def application do
    [mod: {Fw, [%{target: target(Mix.env), compat_version: @compat_version}]},
     applications: apps(Mix.env)]
  end

  # common for test, prod, and dev
  def apps do
    [:logger,
     :nerves_uart,
     :httpotion,
     :poison,
     :gen_stage,
     :nerves_lib,
     :rsa,
     :hulaaki,
     :runtime_tools,
     :mustache,
     :timex,
     :farmbot_auth]
  end

  # on device
  def apps(:prod) do
    apps ++ platform_apps(target(:prod)) ++
    [
      :nerves,
      :nerves_firmware_http,
      :farmbot_configurator
    ]
  end

  # dev
  def apps(:dev) do
    apps ++ [:fake_nerves]
  end

  # test
  def apps(:test) do
    apps ++ [
      :plug,
      :cors_plug,
      :cowboy
    ]
  end

  def deps do
    [
      {:nerves_uart, "~> 0.1.0"},
      {:httpotion, "~> 3.0.0"},
      {:poison, "~> 2.0"},
      {:gen_stage, "~> 0.4"},
      {:nerves_lib, github: "nerves-project/nerves_lib"},
      {:hulaaki, github: "ConnorRigby/hulaaki"},
      {:mustache, "~> 0.0.2"},
      {:timex, "~> 3.0"},
      {:farmbot_auth, github: "Farmbot/farmbot_auth"},
      # {:farmbot_auth, path: "../farmbot_auth"}
    ]
  end

  def deps(:prod) do
    deps ++ platform_deps(target(Mix.env)) ++ system(target(Mix.env)) ++
    [
     {:nerves, "~> 0.3.0"},
     {:nerves_firmware_http, github: "nerves-project/nerves_firmware_http"},
     {:farmbot_configurator, github: "Farmbot/farmbot_configurator"}
    #  {:farmbot_configurator, path: "../farmbot_configurator"}
    ]
  end

  def deps(:test) do
    deps ++ deps(:dev) ++
    [ {:plug, "~> 1.0"},
      {:cors_plug, "~> 1.1"},
      {:cowboy, "~> 1.0.0"} ]
  end

  def deps(:dev) do
    deps ++ [
      {:fake_nerves, github: "ConnorRigby/fake_nerves"},
      # {:fake_nerves, path: "../fake_nerves"},
      {:credo, "~> 0.4"},
      {:dialyxir, "~> 0.4"}]
  end

  def platform_deps("rpi3") do
    [
      {:nerves_leds, "~> 0.7.0"},
      {:elixir_ale, "~> 0.5.5"}
    ]
  end

  def platform_apps("rpi3") do
    [ :nerves_leds,
      :elixir_ale ]
  end

  def aliases(:prod) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

  def aliases(:test) do
    []
  end

  def aliases(:dev) do
    []
  end

  def system("rpi3") do
    [{:"nerves_system_rpi3", git: "https://github.com/ConnorRigby/nerves_system_rpi3.git", tag: "v0.7.5" }]
  end
end
