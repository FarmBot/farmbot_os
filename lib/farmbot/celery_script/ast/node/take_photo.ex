defmodule Farmbot.CeleryScript.AST.Node.TakePhoto do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(_, _, env) do
    env = mutate_env(env)
    Farmbot.CeleryScript.AST.Node.ExecuteScript.execute(%{label: "take-photo"}, [], env)
  end
end
