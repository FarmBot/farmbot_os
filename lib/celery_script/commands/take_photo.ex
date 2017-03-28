defmodule Farmbot.CeleryScript.Command.TakePhoto do
  @moduledoc """
    TestCs
  """

  # alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Takes a photo
      args: %{},
      body: []
  """
  @spec run(%{}, []) :: no_return
  def run(%{}, []) do
    info = Farmbot.BotState.ProcessTracker.lookup :farmware, "take-photo"
    if info do
      Command.start_process(%{label: info.uuid}, [])
    else
      Logger.warn "take-photo is not installed!"
    end
  end
end
