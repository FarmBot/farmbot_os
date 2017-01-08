defmodule Farmbot.FileSystem.Mixfile do
  use Mix.Project
  @version Path.join([__DIR__, "..", "farmbot", "VERSION"]) |> File.read! |> String.strip
  def project do
    [app: :farmbot_filesystem,
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
    [
      mod: {Farmbot.FileSystem, [%{env: Mix.env, target: target(Mix.env)}]},
      applications: [:logger]
    ]
  end

  defp deps, do: []

  defp target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
  defp target(_), do: "development"
end
