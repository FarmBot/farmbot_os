defmodule FarmbotHttp.Mixfile do
  use Mix.Project
  @version Path.join([__DIR__, "..", "farmbot", "VERSION"]) |> File.read! |> String.strip

  def project do
    [app: :farmbot_http,
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
    [extra_applications: [:logger, :poison, :httpoison]]
  end

  defp deps do
    [
      {:poison, "~> 3.0"},
      {:httpoison, "~> 0.10.0"}
    ]
  end
end
