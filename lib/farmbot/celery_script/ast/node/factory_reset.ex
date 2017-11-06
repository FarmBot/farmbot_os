defmodule Farmbot.CeleryScript.AST.Node.FactoryReset do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]

  def execute(_, _, env) do
    env = mutate_env(env)
    Farmbot.System.factory_reset "CeleryScript request."
    {:ok, env}
  end
end
