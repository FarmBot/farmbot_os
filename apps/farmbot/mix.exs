defmodule Farmbot.Mixfile do
  use Mix.Project

  def target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
  def target(_), do: "development"

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
     included_applications: [:gen_mqtt, :json_rpc]]
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
     :runtime_tools,
     :mustache,
     :timex,
     :vmq_commons,
     :amnesia,
     :quantum,
     :farmbot_auth,
     :farmbot_configurator,
     :farmbot_filesystem,
     :farmbot_network,
   ]
  end

  # on device
  def apps(:prod) do
    apps ++ platform_apps(target(:prod)) ++ [:nerves, :nerves_firmware_http]
  end

  # dev apps to start
  def apps(:dev), do: apps ++ []

  # test apps to start
  def apps(:test), do: apps ++ [:faker, :fake_nerves]

  def deps do
    [
      {:nerves_uart, "~> 0.1.0"}, # uart handling
      {:httpotion, "~> 3.0.0"},  # http
      {:poison, "~> 3.0"}, # json
      {:nerves_lib, github: "nerves-project/nerves_lib"}, # this has a good uuid
      {:gen_mqtt, "~> 0.3.1"}, # for rpc transport
      {:gen_stage, "~> 0.4"},
      {:vmq_commons, "1.0.0", manager: :rebar3}, # This is for mqtt to work.
      {:mustache, "~> 0.0.2"}, # string templating
      {:timex, "~> 3.0"}, # managing time. for the scheduler mostly.
      {:quantum, ">= 1.8.1"}, # cron jobs
      {:amnesia, github: "meh/amnesia"}, # database implementation
      {:farmbot_configurator, in_umbrella: true},
      {:farmbot_auth, in_umbrella: true},
      {:farmbot_filesystem, in_umbrella: true},
      {:farmbot_network, in_umbrella: true},
      {:json_rpc, in_umbrella: true}
    ]
  end

  def deps(:prod) do
    deps ++ platform_deps(target(Mix.env)) ++ system(target(Mix.env)) ++
    [
     {:nerves,  "~> 0.4.0"}, # for building on embedded devices
     {:nerves_firmware_http, github: "nerves-project/nerves_firmware_http"}
    ]
  end

  def deps(:test) do
    deps ++ deps(:dev) ++
    [
      {:excoveralls, "~> 0.5"},
      {:faker, "~> 0.7"},
      {:fake_nerves, github: "ConnorRigby/fake_nerves"} # get rid of this one day
    ]
  end

  def deps(:dev) do
    deps ++ [
      {:credo, "~> 0.4"}, # code consistency
      {:ex_doc, "~> 0.14"}, # documentation
      {:dialyxir, "~> 0.4"} # static analysis
    ]
  end

  def platform_deps("rpi3"), do: []
  def platform_deps("qemu"), do: []
  def platform_apps("rpi3"), do: []
  def platform_apps("qemu"), do: []

  # this is for cross compilation to work
  # New version of nerves might not need this?
  def aliases(:prod) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

  # if not in prod mode nothing special.
  def aliases(_), do: []

  # the nerves_system_* dir to use for this build.
  def system(sys), do: [{:"nerves_system_#{sys}", in_umbrella: true}]
end
