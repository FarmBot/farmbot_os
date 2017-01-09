defmodule Farmbot.System.Rpi3.Mixfile do
  use Mix.Project
  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip

  def project do
    [app: :farmbot_system_rpi3,
     version: @version,
     build_path: "../../../_build",
     config_path: "../../../config/config.exs",
     deps_path: "../../../deps",
     lockfile: "../../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
