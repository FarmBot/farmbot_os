defmodule JsonRpc.Mixfile do
  use Mix.Project

  def project do
    [app: :json_rpc,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :poison]]
  end

  defp deps do
    [{:poison, "~> 3.0"}]
  end
end
