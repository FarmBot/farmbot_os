defmodule Farmbot.CeleryScript.AST.Node.Reboot do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(_, _, env) do
    env = mutate_env(env)
    Farmbot.System.reboot("CeleryScript request.")
    {:ok, env}
  end
end
