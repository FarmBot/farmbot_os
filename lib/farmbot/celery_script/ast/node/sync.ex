defmodule Farmbot.CeleryScript.AST.Node.Sync do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(_, _, env) do
    env = mutate_env(env)
    Logger.warn "SYNC BROKE"
    {:ok, env}
  end
end
