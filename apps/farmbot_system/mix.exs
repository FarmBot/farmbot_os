defmodule Farmbot.System.Mixfile do
  use Mix.Project

  @version Path.join([__DIR__, "..", "farmbot", "VERSION"])
  |> File.read!
  |> String.strip


  def target(:prod), do: System.get_env("NERVES_TARGET")
  def target(_), do: "development"

  def project do
    [app: :farmbot_system,
     version: @version,
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     target: target(Mix.env),
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Farmbot.System.Supervisor, [target: target(Mix.env)]}]
  end

  defp deps do
    []
  end
end
