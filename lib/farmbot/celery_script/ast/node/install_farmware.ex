defmodule Farmbot.CeleryScript.AST.Node.InstallFarmware do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:url]

  def execute(%{url: url}, _, env) do
    env = mutate_env(env)
    case Farmbot.Farmware.Installer.install(url) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
