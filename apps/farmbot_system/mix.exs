defmodule Farmbot.System.Mixfile do
  use Mix.Project
  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip

  def target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
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
    [extra_applications: [:logger, :"farmbot_system_#{target(Mix.env)}"]]
  end

  defp deps do
    [{:"farmbot_system_#{target(Mix.env)}", path: "systems/#{target(Mix.env)}"}]
  end
end
