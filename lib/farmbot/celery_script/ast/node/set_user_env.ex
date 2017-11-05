defmodule Farmbot.CeleryScript.AST.Node.SetUserEnv do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(args, body, env) do
    Logger.warn "FIXME"
    {:ok, env}
  end
end
