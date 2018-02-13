defmodule Farmbot.CeleryScript.AST.Node.InstallFirstPartyFarmware do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  @fpf_url "https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/manifest.json"

  def execute(_, _, env) do
    env = mutate_env(env)
    case Farmbot.Farmware.Installer.add_repo(@fpf_url) do
      {:ok, _} -> do_sync_repo(env)
      {:error, :repo_already_exists} -> do_sync_repo(env)
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_sync_repo(env) do
    case Farmbot.Farmware.Installer.sync_repo(@fpf_url) do
      {:ok, _} -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
