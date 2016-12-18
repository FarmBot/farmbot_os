defmodule Farmbot.Auth.Mixfile do
  use Mix.Project

  def project do
    [app: :farmbot_auth,
     version: "0.1.0",
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
     applications: [:logger, :timex, :httpotion, :rsa, :nerves_lib, :poison]]
  end

  defp deps do
    [{:timex, "~> 3.0"},
     {:httpotion, "~> 3.0.0"},
     {:rsa, "~> 0.0.1"},
     {:nerves_lib, github: "nerves-project/nerves_lib"},
     {:poison, "~> 3.0"}]
  end
end
