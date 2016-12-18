defmodule Farmbot.Configurator.Mixfile do
  use Mix.Project
  System.put_env("NODE_ENV", Mix.env |> Atom.to_string)

  def project do
    [app: :farmbot_configurator,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     compilers: [:yecc, :leex, :erlang, :elixir, :xref, :app, :configurator],
     deps: deps]
  end

  def application do
    [mod: {Farmbot.Configurator, []},
     applications: applications]
  end


  defp applications do
    [
      :logger,
      :plug,
      :cors_plug,
      :poison,
      :cowboy
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.0"},
      {:cors_plug, "~> 1.1"},
      {:poison, "~> 3.0"},
      {:cowboy, "~> 1.0.0"},
    ]
  end
end
