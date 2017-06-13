defmodule Farmbot.CeleryScript.Command.PowerOff do
  @moduledoc """
    power_off
  """

  alias   Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    power_off your bot
      args: %{},
      body: []
  """
  @spec run(%{}, [], Context.t) :: Context.t
  def run(%{}, [], context) do
    Farmbot.BotState.set_sync_msg(context, :maintenance)
    Farmbot.Transport.force_state_push(context)

    spawn fn ->
      Logger.warn ">> was told to go down for power off."
      Process.sleep(2000)
      Farmbot.System.power_off()
    end
    context
  end
end
