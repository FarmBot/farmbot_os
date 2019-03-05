defmodule FarmbotExt.MixProject do
  use Mix.Project
  @version Path.join([__DIR__, "..", "VERSION"]) |> File.read!() |> String.trim()
  @elixir_version Path.join([__DIR__, "..", "ELIXIR_VERSION"]) |> File.read!() |> String.trim()

  def project do
    [
      app: :farmbot_ext,
      version: @version,
      elixir: @elixir_version,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["lib", "vendor"],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {FarmbotExt, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:farmbot_core, path: "../farmbot_core", env: Mix.env()},

      # Hack for AMQP to compile
      {:ranch_proxy_protocol,
       override: true,
       git: "https://github.com/heroku/ranch_proxy_protocol.git",
       ref: "4e0f73a385f37cc6f277363695e91f4fc7a81f24"},
      {:ranch, "1.5.0", override: true},
      {:tesla, "~> 1.2"},
      {:hackney, "~> 1.14"},
      {:uuid, "~> 1.1"},
      {:amqp, "~> 1.0"},
      {:excoveralls, "~> 0.10", only: [:test], targets: [:host]},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], targets: [:host], runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev], targets: [:host], runtime: false}
    ]
  end
end
