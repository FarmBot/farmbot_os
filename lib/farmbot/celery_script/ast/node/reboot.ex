defmodule Farmbot.CeleryScript.AST.Node.Reboot do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []
  use Farmbot.Logger

  def execute(_, _, env) do
    env = mutate_env(env)
    Logger.warn 1, "Going down for a reboot!"
    Farmbot.BotState.set_sync_status(:maintenance)
    Farmbot.BotState.force_state_push()
    Farmbot.System.reboot("CeleryScript request.")
    {:ok, env}
  end
end
