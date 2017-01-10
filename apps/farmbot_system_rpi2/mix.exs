defmodule Module.concat([Farmbot, System, "rpi2", Mixfile]) do
  use Mix.Project
  @version Path.join([__DIR__, "..", "farmbot", "VERSION"])
  |> File.read!
  |> String.strip

  def project do
    [app: :farmbot_system_rpi3,
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
    [extra_applications: [:logger, :nerves_interim_wifi, :nerves_firmware_http]]
  end

  defp deps do
    [{:nerves_interim_wifi, github: "nerves-project/nerves_interim_wifi"},
     {:nerves_firmware_http, github: "nerves-project/nerves_firmware_http"},
     {:farmbot_system, in_umbrella: true}]
  end
end
