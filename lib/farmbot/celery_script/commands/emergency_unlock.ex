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
  @spec run(%{}, []) :: no_return
  def run(%{}, []) do
    Farmbot.BotState.set_sync_msg(:sync_now)
    Farmbot.BotState.unlock_bot()
    Farmbot.Serial.Handler.emergency_unlock()
  end
end
