defmodule Farmbot.Mixfile do
  use Mix.Project

  def target(:prod) do
    blah = System.get_env("NERVES_TARGET") || "rpi3"
    System.put_env("NERVES_TARGET", blah)
    blah
  end

  def target(_), do: "development"

  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip
  @compat_version Path.join(__DIR__, "COMPAT")
    |> File.read!
    |> String.strip
    |> String.to_integer

  def commit() do
    {t,_} = System.cmd("git", ["log", "--pretty=format:%h", "-1"])
    t
  end

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
     lockfile: "../../mix.lock",
     aliases:     aliases(Mix.env),
     deps:        deps() ++ system(target(Mix.env)),
     name: "Farmbot",
     source_url: "https://github.com/Farmbot/farmbot_os",
     homepage_url: "http://farmbot.io",
     docs: [main: "farmbot", # The main page in the docs
            extras: ["README.md"]]
   ]
  end

  def application do
    [mod:
      { Farmbot,
        [
          %{
            target: target(Mix.env),
            compat_version: @compat_version,
            version: @version,
            commit: commit()
            }
        ]
      },
     applications: applications(),
     included_applications: [:gen_mqtt]]
  end

  # common for test, prod, and dev
  def applications do
    [
      :logger,
      :nerves_uart,
      :httpotion,
      :poison,
      :nerves_lib,
      :rsa,
      :runtime_tools,
      :mustache,
      :vmq_commons,
      :amnesia,
      :gen_stage,
      :nerves,
      :"farmbot_system_#{target(Mix.env)}",
      :farmbot_system,
      :farmbot_auth,
      :farmbot_configurator,
      :quantum, # Quantum needs to start AFTER farmbot_system, so we can set up its dirs
      :timex, # Timex needs to start AFTER farmbot_system, so we can set up its dirs
   ]
  end

  def deps do
    [
      {:nerves_uart, "~> 0.1.0"}, # uart handling
      {:httpotion, "~> 3.0.0"},  # http
      {:poison, "~> 3.0"}, # json
      {:nerves_lib, github: "nerves-project/nerves_lib"}, # this has a good uuid
      {:gen_mqtt, "~> 0.3.1"}, # for rpc transport
      {:vmq_commons, "1.0.0", manager: :rebar3}, # This is for mqtt to work.
      {:mustache, "~> 0.0.2"}, # string templating
      {:timex, "~> 3.0"}, # managing time. for the scheduler mostly.
      {:quantum, ">= 1.8.1"}, # cron jobs
      {:amnesia, github: "meh/amnesia"}, # database implementation
      {:gen_stage, "~> 0.7"},
      {:nerves, "~> 0.4.0"},
      {:credo, "0.6.0-rc1",  only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev},
      {:faker, "~> 0.7", only: :test},
      {:"farmbot_system_#{target(Mix.env)}", in_umbrella: true},
      {:farmbot_system,       in_umbrella: true},
      {:farmbot_auth,         in_umbrella: true},
      {:farmbot_configurator, in_umbrella: true},
    ]
  end

  # this is for cross compilation to work
  # New version of nerves might not need this?
  def aliases(:prod) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"],
     "firmware.upload": ["farmbot.upload"]]
  end

  # if not in prod mode nothing special.
  def aliases(_), do: []

  # the nerves_system_* dir to use for this build.
  def system("development"), do: []
  def system(sys) do
    if File.exists?("../NERVES_SYSTEM_#{sys}") do
      System.put_env("NERVES_SYSTEM", "../NERVES_SYSTEM_#{sys}")
    end

    # if the system is local (because we have changes to it) use that
    if File.exists?("../nerves_system_#{sys}") do
      [{:"nerves_system_#{sys}", in_umbrella: true}]
    else
      # if its not local we can try nerves. It probably wont work tho.
      [{:"nerves_system_#{sys}", github: "nerves-project/nerves_system_#{sys}"}]
    end
  end

  def webpack do
    File.cd "../farmbot_configurator"
    Farmbot.Configurator.WebPack.start_link
  end
end
