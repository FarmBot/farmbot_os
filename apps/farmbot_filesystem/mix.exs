defmodule Farmbot.Filesystem.Mixfile do
  use Mix.Project

  def project do
    [app: :farmbot_filesystem,
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
    [
      mod: {Farmbot.Filesystem.Supervisor, [{Mix.env, target(Mix.env)}]},
      applications: [:logger]
    ]
  end

  defp deps do
    []
  end

  defp target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
  defp target(_), do: System.get_env("NERVES_TARGET") || "development"
end
