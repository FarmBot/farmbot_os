defmodule Module.concat([Farmbot,System,"development",Mixfile]) do
  use Mix.Project
  @version Path.join([__DIR__, "..", "farmbot", "VERSION"])
  |> File.read!
  |> String.strip

  def project do
    [app: :farmbot_system_development,
     version: @version,
     build_path: "../../_build",
     config_path: "../../farmbot_config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix-devlopment.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:farmbot_system, in_umbrella: true}]
  end
end
