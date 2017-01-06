defmodule Farmbot.Auth.Mixfile do
  use Mix.Project
  @version Path.join([__DIR__, "..", "farmbot", "VERSION"]) |> File.read! |> String.strip


  def project do
    [app: :farmbot_auth,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     deps: deps()]
  end

  def application do
    [mod: {Farmbot.Auth, []},
     applications: [:logger, :httpotion, :rsa, :nerves_lib, :poison]]
  end

  defp deps do
    [
      {:httpotion, "~> 3.0.0"},
      {:rsa, "~> 0.0.1"},
      {:nerves_lib, github: "nerves-project/nerves_lib"},
      {:poison, "~> 3.0"},
      {:farmbot_filesystem, in_umbrella: true}
   ]
  end
end
