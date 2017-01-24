defmodule Farmware.Mixfile do
  use Mix.Project
  @version Path.join([__DIR__, "..", "farmbot", "VERSION"])
  |> File.read!
  |> String.strip

  def project do
    [app: :farmware,
     version: @version,
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger, :ex_json_schema],
     mod: {Farmware.Application, []}]
  end

  defp deps do
    [
      {:gen_stage, "0.10.0"},
      {:farmbot_system, in_umbrella: true},
      {:ex_json_schema, "~> 0.5.3"},
      {:httpoison, "~> 0.10.0"}
    ]
  end
end
