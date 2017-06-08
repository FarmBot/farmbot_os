defmodule Farmbot.CeleryScript.Command.EmergencyLock do
  @moduledoc """
    EmergencyLock
  """

  alias Farmbot.CeleryScript.{Command, Error}
  require Logger

  @behaviour Command

  @doc ~s"""
    Locks the bot from movement until unlocked
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    if Farmbot.BotState.locked?(context) do
      raise Error, message: "Bot is already locked"
    else
      do_lock(context)
    end
    context
  end

  defp do_lock(context) do
    :ok = Farmbot.Serial.Handler.emergency_lock(context)
    :ok = Farmbot.BotState.set_sync_msg(context, :locked)
    :ok = Farmbot.BotState.lock_bot(context)
  end
end
