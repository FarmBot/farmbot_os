defmodule Farmbot.CeleryScript.AST.Node.AddPoint do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:location]

  def execute(_, _, env) do
    env = mutate_env(env)
    {:ok, env}
  end
end
