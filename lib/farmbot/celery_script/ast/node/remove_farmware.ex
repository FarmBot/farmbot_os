defmodule Farmbot.CeleryScript.AST.Node.RemoveFarmware do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]

  def execute(%{package: {:farmware, name}}, _, env) do
    env = mutate_env(env)
    case Farmbot.Farmware.lookup(name) do
      {:ok, fw} -> do_uninstall(fw, env)
      {:error, _} -> {:ok, env}
    end
  end

  def do_uninstall(%Farmbot.Farmware{} = fw, env) do
    case Farmbot.Farmware.Installer.uninstall(fw) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason,  env}
    end
  end
end
