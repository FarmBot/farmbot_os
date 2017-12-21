defmodule Farmbot.CeleryScript.AST.Node.PowerOff do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(_, _, env) do
    env = mutate_env(env)
    Farmbot.BotState.set_sync_status(:maintenance)
    Farmbot.BotState.force_state_push()
    Farmbot.System.shutdown("CeleryScript request")
    {:ok, env}
  end
end
