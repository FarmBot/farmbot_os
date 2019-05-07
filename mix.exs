defmodule FarmbotSupport.MixProject do
  ################################################################################
  ######  WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING   ######
  ######        This is not the root mix.exs the farmbot application        ######
  ######           This OTP application is for test support only.           ######
  ######  WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING   ######
  ################################################################################

  use Mix.Project
  @version Path.join([__DIR__, "VERSION"]) |> File.read!() |> String.trim()
  @elixir_version Path.join([__DIR__, "ELIXIR_VERSION"]) |> File.read!() |> String.trim()

  def project do
    [
      app: :farmbot_support,
      version: @version,
      elixir: @elixir_version,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["support"],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        test: :test,
        coveralls: :test,
        "coveralls.circle": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:excoveralls, "~> 0.10", only: [:test], targets: [:host]},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], targets: [:host], runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev], targets: [:host], runtime: false}
    ]
  end
end
