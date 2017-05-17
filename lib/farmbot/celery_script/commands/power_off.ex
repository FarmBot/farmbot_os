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
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    Farmbot.System.power_off()
    context
    # ^ lol
  end
end
