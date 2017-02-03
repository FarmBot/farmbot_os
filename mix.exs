defmodule FarmbotOs.Mixfile do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip

  def project do
    [apps_path: "apps",
     elixir: "~> 1.4",
     version: @version,
     target: @target,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     default_task: "warning",
     aliases: aliases(),
     deps: []]
  end

  defp aliases() do
    ["firmware":        ["warning"],
     "firmware.burn":   ["warning"],
     "firmware.upload": ["warning"]]
  end
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
