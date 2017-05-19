defmodule Farmbot.CeleryScript.Command.Reboot do
  @moduledoc """
    Reboot
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast
  @behaviour Command

  @doc ~s"""
    reboots your bot
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    Farmbot.System.reboot()
    context
    # ^ LOL
  end
end
