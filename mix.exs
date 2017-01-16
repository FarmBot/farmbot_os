defmodule FarmbotOs.Mixfile do
  use Mix.Project

  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip

  def project do
    [apps_path: "apps",
     version: @version,
     target: target(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps, do: []

  def target(:prod) do
    blah = System.get_env("NERVES_TARGET") || "rpi3"
    System.put_env("NERVES_TARGET", blah)
    blah
  end

  def target(_), do: "development"
end
