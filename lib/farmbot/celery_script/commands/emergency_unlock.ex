defmodule Farmbot.CeleryScript.Command.EmergencyUnlock do
  @moduledoc """
    EmergencyUnlock
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    unlocks the bot allowing movement again.
      args: %{},
      body: []
  """
  @spec run(%{}, []) :: no_return
  def run(%{}, []) do
    Command.shrug(%{message: "sorry about that. Farmbot needs to reboot"}, [])
    Farmbot.BotState.unlock_bot()
  end
end
