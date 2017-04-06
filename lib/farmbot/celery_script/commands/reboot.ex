defmodule Farmbot.CeleryScript.Command.Reboot do
  @moduledoc """
    Reboot
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    reboots your bot
      args: %{},
      body: []
  """
  @spec run(%{}, []) :: no_return
  def run(%{}, []) do
    Farmbot.System.reboot()
  end
end
