defmodule Farmbot.CeleryScript.Command.Reboot do
  @moduledoc """
    Reboot
  """

  require    Logger
  alias      Farmbot.CeleryScript.Command
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    reboots your bot
      args: %{},
      body: []
  """
  @spec run(%{}, [], Context.t) :: Context.t
  def run(%{}, [], %Context{} = context) do
    spawn(fn ->
      Farmbot.BotState.set_sync_msg(context, :maintenance)
      Farmbot.Transport.force_state_push(context)
      Logger.warn ">> was told to reboot. See you soon!"
      Process.sleep(2000)
      Farmbot.System.reboot()
    end) |> Process.link()
    context
  end
end
