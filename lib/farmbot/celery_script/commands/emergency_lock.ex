defmodule Farmbot.CeleryScript.Command.EmergencyLock do
  @moduledoc """
    EmergencyLock
  """

  alias Farmbot.CeleryScript.Command
  require Logger

  @behaviour Command

  @doc ~s"""
    Locks the bot from movement until unlocked
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    if Farmbot.BotState.locked? do
      Logger.info "Bot already locked", type: :warn
    else
      Farmbot.BotState.set_sync_msg(:locked)
      Farmbot.BotState.lock_bot()
      Farmbot.Serial.Handler.emergency_lock(context)
    end
    context
  end
end
