defmodule Farmbot.Network.Mixfile do
  use Mix.Project

  def project do
    [app: :farmbot_network,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :poison, :nerves_interim_wifi],
     mod: {Farmbot.Network, [%{hardware: target(Mix.env)}]}]
  end

  defp deps, do: [
    {:poison, "~> 3.0"},
    {:json_rpc, in_umbrella: true},
    {:nerves_interim_wifi, "~> 0.1.0"}
  ]
  defp target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
  defp target(_), do: "development"
end
