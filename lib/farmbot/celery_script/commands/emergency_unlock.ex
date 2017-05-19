defmodule Farmbot.CeleryScript.Command.EmergencyUnlock do
  @moduledoc """
    EmergencyUnlock
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    unlocks bot from movement
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    Farmbot.BotState.set_sync_msg(context, :sync_now)
    Farmbot.BotState.unlock_bot(context)
    Farmbot.Serial.Handler.emergency_unlock(context)
  end
end
