defmodule Farmbot.Configurator.Mixfile do
  use Mix.Project
  @version Path.join([__DIR__, "..", "farmbot", "VERSION"]) |> File.read! |> String.strip
  @target System.get_env("MIX_TARGET") || "host"

  def project do
    [app: :farmbot_configurator,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     compilers:  Mix.compilers ++ maybe_use_webpack(),
     target: @target,
     webpack_watch: Mix.env == :dev,
     webpack_cd: "../farmbot_configurator",
     deps: deps()]
  end

  # TODO(connor): Build this into `:ex_webpack`
  defp maybe_use_webpack() do
    case System.get_env("NO_WEBPACK") do
      "true" -> []
      _ -> [:ex_webpack]
    end
  end

  def application do
    [mod: {Farmbot.Configurator, []},
     applications: applications()]
  end


  defp applications, do: [:logger, :plug, :cors_plug, :poison, :cowboy]

  defp deps do
    [
      {:plug, "~> 1.0"},
      {:cors_plug, "~> 1.1"},
      {:poison, "~> 3.0"},
      {:cowboy, "~> 1.0.0"},
      {:ex_webpack, "~> 0.1.1", runtime: false},
      {:farmbot_auth, in_umbrella: true},
      {:farmbot_system, in_umbrella: true}
    ]
  end
end
