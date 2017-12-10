defmodule Farmbot.CeleryScript.AST.Node.EmergencyLock do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []
  use Farmbot.Logger

  def execute(_, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.emergency_lock do
      {:error, :emergency_lock} ->
        Logger.error 1, "Farmbot is E Stopped!"
        {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
