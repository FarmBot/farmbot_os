defmodule Farmbot.Mixfile do
  use Mix.Project
  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip

  defp commit() do
    {t,_} = System.cmd("git", ["log", "--pretty=format:%h", "-1"])
    t
  end

  Mix.shell.info([:green, """
  Env
    MIX_TARGET:   #{@target}
    MIX_ENV:      #{Mix.env}
  """, :reset])

  def project do
    [app: :farmbot,
     description: "The Brains of the Farmbot Project",
     package: package(),
     test_coverage: [tool: ExCoveralls],
     version: @version,
     target: @target,
     commit: commit(),
     archives: [nerves_bootstrap: "~> 0.6.0"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     build_path:  "_build/#{Mix.env()}/#{@target}",
     deps_path:   "deps/#{Mix.env()}/#{@target}",
     images_path: "images/#{Mix.env()}/#{@target}",
     config_path: "config/config.exs",
     lockfile: "mix.lock",
     elixirc_paths: elixirc_paths(Mix.env, @target),
     aliases: aliases(@target),
     deps: deps() ++ deps(@target),
     dialyzer: [
       plt_add_deps: :transitive,
       flags:        []
     ],
     preferred_cli_env: [
       "vcr":              :test,
       "vcr.delete":       :test,
       "vcr.check":        :test,
       "vcr.show":         :test,
       "all_test":         :test,
       "test":             :test,
       "coveralls":        :test,
       "coveralls.detail": :test,
       "coveralls.post":   :test,
       "coveralls.html":   :test,
       "coveralls.travis": :test
     ],
     source_url: "https://github.com/Farmbot/farmbot_os",
     homepage_url: "http://farmbot.io",
     docs: [
       main: "Farmbot",
       logo: "priv/static/farmbot_logo.png",
       extras: ["./docs/*"]
     ]
   ]
  end


  def application do
    [mod: {Farmbot, []}]
  end

  defp deps do
    [
      {:nerves, "~> 0.7.5"},

      {:gen_mqtt, "~> 0.3.1"},
      {:vmq_commons, "1.0.0", manager: :rebar3},

      {:poison, "~> 3.0"},
      {:ex_json_schema, "~> 0.5.3"},
      {:rsa, "~> 0.0.1"},
      {:httpoison, "~> 0.13.0"},

      {:tzdata, "~> 0.1.201601", override: true},
      {:timex, "~> 3.1.13"},

      {:fs, "~> 0.9.1"},
      {:nerves_uart, "0.1.2"},
      {:uuid, "~> 1.1" },
    ]
  end

  defp deps("host") do
    [

      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev},
      {:excoveralls, "~> 0.6", only: :test},
      {:mock, "~> 0.2.0", only: :test},


    ]
  end

  defp deps(_target) do
    [
      {:ex_syslogger, github: "slashmili/ex_syslogger", only: :prod}
    ]
  end

  defp package do
    [name: "Farmbot OS",
    maintainers: "Farmbot.io",
    licenses: "MIT"]
  end

  defp elixirc_paths(:test, "host") do
    ["./lib", "./nerves/host", "./test/support"]
  end

  defp elixirc_paths(_env, target) do
    ["./lib", "./nerves/#{target}"]
  end

  defp aliases("host"), do: []

  defp aliases(_system) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"],
     "firmware.upload": ["farmbot.upload"],
     "firmware.sign":   ["farmbot.sign"]
   ]
  end
end
