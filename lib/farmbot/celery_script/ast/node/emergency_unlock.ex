defmodule Farmbot.CeleryScript.AST.Node.EmergencyUnlock do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(_, _, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.emergency_unlock do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
