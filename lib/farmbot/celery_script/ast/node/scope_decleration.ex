defmodule Farmbot.CeleryScript.AST.Node.ScopeDeclaration do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(_, _, env) do
    env = mutate_env(env)
    {:ok, env}
  end
end
