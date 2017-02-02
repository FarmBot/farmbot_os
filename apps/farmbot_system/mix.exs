defmodule Farmbot.System.Mixfile do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join([__DIR__, "..", "farmbot", "VERSION"])
  |> File.read!
  |> String.strip

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
     target: @target,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger, :httpoison, :gen_stage],
     mod: {Farmbot.System.Supervisor, [target: @target]}]
  end

  defp deps do
    [
      {:httpoison, github: "edgurgel/httpoison"},
      {:gen_stage, "0.11.0"}
    ]
  end
end
