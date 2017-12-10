defmodule Farmbot.CeleryScript.AST.Node.UpdateFarmware do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]

  def execute(%{package: {:farmware, package}}, body, env) do
    env = mutate_env(env)
    case Farmbot.Farmware.lookup(package) do
      {:ok, %Farmbot.Farmware{} = fw} ->
        Farmbot.CeleryScript.AST.Node.InstallFarmware.execute(%{url: fw.url}, body, env)
      {:error, reason} -> {:error, reason, env}
    end
  end
end
