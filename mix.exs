defmodule Fw.Mixfile do
  Code.load_file("tasks.exs")

  use Mix.Project

  @target System.get_env("NERVES_TARGET") || "rpi3"
  @version Path.join(__DIR__, "VERSION")
    |> File.read!
    |> String.strip

  def project do
    [app: :fw,
     version: @version,
     target: @target,
     archives: [nerves_bootstrap: "~> 0.1.4"],
     deps_path: "deps/#{@target}",
     build_path: "_build/#{@target}",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     config_path: "config/config.exs",
     aliases: aliases(Mix.env),
     deps: deps(Mix.env) ]
  end

  def application do
    [mod: {Fw, []},
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
     :cowboy,
     :plug,
     :cors_plug,
     :hulaaki,
     :runtime_tools]
  end

  # on device
  def apps(:prod) do
    apps ++ platform_apps(@target) ++
    [
      :nerves,
      :nerves_firmware_http
    ]
  end

  # dev
  def apps(:dev) do
    apps ++ [:fake_nerves]
  end

  # test
  def apps(:test) do
    apps
  end

  def deps do
    [
      {:nerves_uart, "~> 0.1.0"},
      {:httpotion, "~> 3.0.0"},
      {:poison, "~> 2.0"},
      {:gen_stage, "~> 0.4"},
      {:nerves_lib, github: "nerves-project/nerves_lib"},
      {:rsa, "~> 0.0.1"},
      {:cowboy, "~> 1.0.0"},
      {:plug, "~> 1.0"},
      {:cors_plug, "~> 1.1"},
      {:hulaaki, github: "ConnorRigby/hulaaki"}
    ]
  end

  def deps(:prod) do
    deps ++ platform_deps(@target) ++ system(@target) ++
    [
     {:nerves, "~> 0.3.0"},
     {:nerves_firmware_http, github: "nerves-project/nerves_firmware_http"},
    ]
  end

  def deps(:test) do
    deps ++ deps(:dev)
  end

  def deps(:dev) do
    deps ++ [{:fake_nerves, github: "ConnorRigby/fake_nerves"}]
  end

  def platform_deps("rpi3") do
    [
      {:nerves_networking, github: "nerves-project/nerves_networking"},
      {:nerves_interim_wifi, github: "nerves-project/nerves_interim_wifi" },
      {:elixir_ale, "~> 0.5.5"}
    ]
  end

  def platform_apps("rpi3") do
    [ :nerves_networking,
      :nerves_interim_wifi,
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
    [{:"nerves_system_rpi3", git: "https://github.com/ConnorRigby/nerves_system_rpi3.git", tag: "v0.7.2-farmbot" }]
  end
end
