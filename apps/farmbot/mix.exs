defmodule Farmbot.Mixfile do
  use Mix.Project
  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip
  @compat_version Path.join(__DIR__, "COMPAT")
    |> File.read!
    |> String.strip
    |> String.to_integer

  defp commit() do
    {t,_} = System.cmd("git", ["log", "--pretty=format:%h", "-1"])
    t
  end

  def project do
    [app: :farmbot,
     test_coverage: [tool: ExCoveralls],
     version: @version,
     target:  @target,
     archives: [nerves_bootstrap: "~> 0.2.0"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     build_path:  "../../_build/#{@target}",
     deps_path:   "../../deps/#{@target}",
     images_path: "../../images/#{@target}",
     config_path: "../../config/config.exs",
     lockfile: "../../mix.lock",
     aliases: aliases(@target),
     deps:    deps() ++ system(@target),
     name: "Farmbot",
     source_url: "https://github.com/Farmbot/farmbot_os",
     homepage_url: "http://farmbot.io",
     docs: [main: "Farmbot", extras: ["../../README.md", "../../BUILDING.md"]]
   ]
  end

  def application do
    [mod:
      {Farmbot,
       [%{target: @target,
          compat_version: @compat_version,
          version: @version,
          commit: commit()}]},
     applications: applications(),
     included_applications: [:gen_mqtt, :ex_json_schema]]
  end

  # common for test, prod, and dev
  defp applications do
    [
      :logger,
      :nerves_uart,
      :poison,
      :httpoison,
      :nerves_lib,
      :runtime_tools,
      :mustache,
      :vmq_commons,
      :amnesia,
      :gen_stage,
      :"farmbot_system_#{@target}",
      :farmbot_system,
      :farmbot_auth,
      :farmbot_configurator,
      :quantum, # Quantum needs to start AFTER farmbot_system, so we can set up its dirs
      :timex, # Timex needs to start AFTER farmbot_system, so we can set up its dirs
   ]
  end

  defp deps do
    [
      {:nerves_uart, "~> 0.1.0"}, # uart handling
      {:poison, "~> 3.0"}, # json
      {:httpoison, github: "edgurgel/httpoison"},
      {:nerves_lib, github: "nerves-project/nerves_lib"}, # this has a good uuid
      {:gen_mqtt, "~> 0.3.1"}, # for rpc transport
      {:vmq_commons, "1.0.0", manager: :rebar3}, # This is for mqtt to work.
      {:mustache, "~> 0.0.2"}, # string templating
      {:timex, "~> 3.0"}, # managing time. for the scheduler mostly.
      {:quantum, ">= 1.8.1"}, # cron jobs
      {:amnesia, github: "meh/amnesia"}, # database implementation
      {:gen_stage, "0.11.0"},
      {:ex_json_schema, "~> 0.5.3"},
      {:credo, "0.6.0-rc1",  only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:faker, "~> 0.7", only: :test},
      # Farmbot Stuff
      {:"farmbot_system_#{@target}", in_umbrella: true},
      {:farmbot_system,              in_umbrella: true},
      {:farmbot_auth,                in_umbrella: true},
      {:farmbot_configurator,        in_umbrella: true}
    ]
  end

  # this is for cross compilation to work
  # New version of nerves might not need this?
  defp aliases("host"), do: [
    "firmware": ["farmbot.warning"],
    "credo": ["credo list --only readability,warning,todo,inspect,refactor --ignore-checks todo,spec"],
    "test": ["test", "credo"]]

  # TODO(Connor) Maybe warn if building firmware in dev mode?
  defp aliases(_system) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
      "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"],
      "firmware.upload": ["farmbot.upload"]]
  end

  # the nerves_system_* dir to use for this build.
  defp system("host"), do: []
  defp system(sys) do
    if File.exists?("../NERVES_SYSTEM_#{sys}"),
      do: System.put_env("NERVES_SYSTEM", "../NERVES_SYSTEM_#{sys}")

    # if the system is local (because we have changes to it) use that
    if File.exists?("../nerves_system_#{sys}"),
      do:   [{:"nerves_system_#{sys}", in_umbrella: true}],
      else: Mix.raise("There is no existing system package for #{sys}")
  end
end
