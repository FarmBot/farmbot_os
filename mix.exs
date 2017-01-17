defmodule FarmbotOs.Mixfile do
  use Mix.Project

  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip

  def project do
    [apps_path: "apps",
     elixir: "~> 1.4",
     version: @version,
     target: target(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     default_task: "warning",
     deps: []]
  end

  defp target(:prod) do
    blah = System.get_env("NERVES_TARGET") || "rpi3"
    System.put_env("NERVES_TARGET", blah)
    blah
  end

  defp target(_), do: "development"
end

defmodule Mix.Tasks.Warning do
  use Mix.Task

  def run(_) do
    Mix.raise(
    """
    Welcome to the Farmbot Build Environment.
    You probably meant to be in the "apps/farmbot" directory.
    """)
  end
end
