defmodule Farmbot.Configurator.Mixfile do
  use Mix.Project
  System.put_env("NODE_ENV", Mix.env |> Atom.to_string)
  def target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
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
     target: target(Mix.env),
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
      {:httpotion, "~> 3.0.0"},
      {:farmbot_auth, in_umbrella: true},
      {:farmbot_system, in_umbrella: true}
    ]
  end
end
