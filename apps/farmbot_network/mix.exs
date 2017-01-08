defmodule Farmbot.Network.Mixfile do
  use Mix.Project
  @version Path.join([__DIR__, "..", "farmbot", "VERSION"]) |> File.read! |> String.strip
  def project do
    [app: :farmbot_network,
     version: @version,
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :poison, :nerves_interim_wifi],
     mod: {Farmbot.Network, [target: target(Mix.env)]}]
  end

  defp deps, do: [
    {:poison, "~> 3.0"},
    {:nerves_interim_wifi, "~> 0.1.0"},
    {:farmbot_auth, in_umbrella: true}
  ]
  defp target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
  defp target(_), do: "development"
end
