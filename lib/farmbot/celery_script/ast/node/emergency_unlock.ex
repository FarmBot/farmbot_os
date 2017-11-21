defmodule Farmbot.CeleryScript.AST.Node.EmergencyUnlock do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []
  use Farmbot.Logger

  def execute(_, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.emergency_unlock do
      :ok ->
        Logger.success 1, "Bot is Successfully unlocked."
        {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
