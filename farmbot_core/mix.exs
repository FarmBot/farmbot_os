defmodule FarmbotCore.MixProject do
  use Mix.Project
  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join([__DIR__, "..", "VERSION"]) |> File.read!() |> String.trim()
  @branch System.cmd("git", ~w"rev-parse --abbrev-ref HEAD") |> elem(0) |> String.trim()
  @elixir_version Path.join([__DIR__, "..", "ELIXIR_VERSION"]) |> File.read!() |> String.trim()

  defp commit do
    System.cmd("git", ~w"rev-parse --verify HEAD") |> elem(0) |> String.trim()
  end

  defp arduino_commit do
    opts = [cd: Path.join("c_src", "farmbot-arduino-firmware")]

    System.cmd("git", ~w"rev-parse --verify HEAD", opts)
    |> elem(0)
    |> String.trim()
  end

  def project do
    [
      app: :farmbot_core,
      description: "The Brains of the Farmbot Project",
      elixir: @elixir_version,
      make_clean: ["clean"],
      make_env: make_env(),
      make_cwd: __DIR__,
      compilers: [:elixir_make] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      version: @version,
      target: @target,
      branch: @branch,
      commit: commit(),
      arduino_commit: arduino_commit(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_add_deps: :transitive,
        plt_add_apps: [:mix],
        flags: []
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      source_url: "https://github.com/Farmbot/farmbot_os",
      homepage_url: "http://farmbot.io"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Farmbot.Core, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:farmbot_celery_script, path: "../farmbot_celery_script", env: Mix.env()},
      {:farmbot_firmware, path: "../farmbot_firmware", env: Mix.env()},
      {:elixir_make, "~> 0.4", runtime: false},
      {:sqlite_ecto2, "~> 2.3"},
      {:timex, "~> 3.4"},
      {:jason, "~> 1.1"},
      {:muontrap, "~> 0.4.0"},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19", only: [:docs], runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp make_env do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "MAKE_CWD" => __DIR__,
          "ERL_EI_INCLUDE_DIR" => Path.join([:code.root_dir(), "usr", "include"]),
          "ERL_EI_LIBDIR" => Path.join([:code.root_dir(), "usr", "lib"]),
          "MIX_TARGET" => @target
        }

      _ ->
        %{"MAKE_CWD" => __DIR__}
    end
  end

  defp elixirc_paths(:test) do
    ["lib", "../test/support"]
  end

  defp elixirc_paths(:dev) do
    ["lib", "../test/support"]
  end

  defp elixirc_paths(_), do: ["lib"]

  defp aliases,
    do: [
      test: ["ecto.drop", "ecto.migrate", "test"]
    ]
end
