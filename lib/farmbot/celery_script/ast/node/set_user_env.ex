defmodule Farmbot.CeleryScript.AST.Node.SetUserEnv do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []
  use Farmbot.Logger

  def execute(args, body, env) do
    env = mutate_env(env)
    Logger.warn 1, "FIXME"
    {:ok, env}
  end
end
