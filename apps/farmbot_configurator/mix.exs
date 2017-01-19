defmodule Farmbot.Configurator.Mixfile do
  use Mix.Project
  def target(:prod), do: System.get_env("NERVES_TARGET")
  def target(_), do: "development"

  def project do
    [app: :farmbot_configurator,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     compilers:  [:ex_webpack] ++ Mix.compilers,
     target: target(Mix.env),
     watch_webpack: Mix.env == :dev,
     deps: deps()]
  end

  def application do
    [ mod: {Farmbot.Configurator, []},
      applications: applications() ]
  end


  defp applications do
    [:logger, :plug, :cors_plug, :poison, :cowboy]
  end

  defp deps do
    [
      {:plug, "~> 1.0"},
      {:cors_plug, "~> 1.1"},
      {:poison, "~> 3.0"},
      {:cowboy, "~> 1.0.0"},
      {:ex_webpack, "~> 0.1.0", runtime: false},
      {:farmbot_auth, in_umbrella: true},
      {:farmbot_system, in_umbrella: true}
    ]
  end
end
