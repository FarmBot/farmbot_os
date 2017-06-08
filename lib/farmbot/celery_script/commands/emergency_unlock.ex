defmodule Farmbot.CeleryScript.Command.EmergencyUnlock do
  @moduledoc """
    EmergencyUnlock
  """

  alias Farmbot.CeleryScript.{Command, Message}
  @behaviour Command

  @doc ~s"""
    unlocks bot from movement
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    if Farmbot.BotState.locked?(context) do
      :ok = Farmbot.Serial.Handler.emergency_unlock(context)
      :ok = Farmbot.BotState.unlock_bot(context)
      :ok = Farmbot.BotState.set_sync_msg(context, :sync_now)
      context
    else
      raise Error, message: "Bot is not locked"
    end

  end
end
