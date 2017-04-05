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
  @spec run(%{}, []) :: no_return
  def run(%{}, []) do
    Farmbot.System.power_off()
  end
end
