defmodule Farmbot.CeleryScript.Command.Reboot do
  @moduledoc """
    Reboot
  """

  require    Logger
  alias      Farmbot.CeleryScript.{Ast, Command}
  @behaviour Command

  @doc ~s"""
    reboots your bot
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    spawn fn ->
      Logger.warn ">> was told to reboot. See you soon!"
      Process.sleep(2000)
      Farmbot.System.reboot()
    end
    context
  end
end
