defmodule FarmbotOs.Mixfile do
  use Mix.Project

  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip

  def project do
    [apps_path: "apps",
     version: @version,
     target: target(Mix.env),
     config_path: "farmbot_config.exs",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     default_task: "hello",
     deps: deps()]
  end

  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps(), do: []

  def target(:prod) do
    blah = System.get_env("NERVES_TARGET") || "rpi3"
    System.put_env("NERVES_TARGET", blah)
    blah
  end

  def target(_), do: "development"
end

defmodule Mix.Tasks.Hello do
  use Mix.Task

  def run(_) do
    File.cd "apps/farmbot"
    t = File.ls!
    Mix.shell.info "hello #{inspect t}"
  end
end
