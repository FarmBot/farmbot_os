defmodule NervesPackagesFarmbot.Mixfile do
  use Mix.Project

  @version Path.join([__DIR__, "..", "farmbot", "VERSION"])
  |> File.read!
  |> String.strip


  def project do
    [app: :nerves_packages_farmbot,
     version: @version,
     elixir: "~> 1.4",
     archives: [nerves_bootstrap: "~> 0.2.1"],
     aliases: ["deps.precompile": ["nerves.env", "deps.precompile"]],
     compilers: Mix.compilers ++ [:nerves_package],
     description: description(),
     package: package(),
     lockfile: "../../mix.lock",
     deps: deps()]
  end

  def application, do: []

  defp deps do
    [{:nerves, "~> 0.4.0"},
     {:nerves_system_br, "~> 0.8.1"}]
  end

  defp description do
    """
    Buildroot packages common to Farmbot
    """
  end

  defp package do
    [maintainers: ["Connor Rigby"],
    files: ["mix.exs", "Config.in", ".gitignore"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/farmbot/farmbot_os"}]
  end
end
