defmodule Farmbot.CeleryScript.Command.PowerOff do
  @moduledoc """
    power_off
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    power_off your bot
      args: %{},
      body: []
  """
  @spec run(%{}, [], Context.t) :: Context.t
  def run(%{}, [], context) do
    spawn fn ->
      Farmbot.BotState.set_sync_msg(context, :maintenance)
      Process.sleep(2000)
      Farmbot.System.power_off()
    end
    context
  end
end
