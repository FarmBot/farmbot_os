defmodule FarmbotOs.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     target: target(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps, do: []

  defp target(:prod), do: System.get_env("NERVES_TARGET") || "rpi3"
  defp target(_), do: System.get_env("NERVES_TARGET") || "development"
end
