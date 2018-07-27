defmodule Farmbot.CeleryScript.AST.Node.Reboot do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]
  use Farmbot.Logger

  def execute(%{package: :arduino_firmware}, _, env) do
    env = mutate_env(env)
    Logger.warn 1, "Reinitializing Arduino Firmware."
    Farmbot.BotState.set_sync_status(:maintenance)
    Farmbot.Firmware.Supervisor.reinitialize()
    {:ok, env}
  end

  def execute(_, _, env) do
    env = mutate_env(env)
    Logger.warn 1, "Going down for a reboot!"
    Farmbot.BotState.set_sync_status(:maintenance)
    Farmbot.BotState.force_state_push()
    Farmbot.System.reboot("CeleryScript request.")
    {:ok, env}
  end
end
