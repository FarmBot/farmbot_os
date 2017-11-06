defmodule Farmbot.CeleryScript.AST.Node.UpdateFarmware do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]

  def execute(%{package: args}, body, env) do
    env = mutate_env(env)
    Farmbot.CeleryScript.AST.Node.InstallFarmware.execute(args, body, env)
  end
end
