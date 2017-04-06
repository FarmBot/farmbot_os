defmodule Farmbot.CeleryScript.Command.StartProcess do
  @moduledoc """
    StartProcess
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    Starts a FarmProcess
      args: %{label: String.t},
      body: []
  """
  @spec run(%{label: String.t}, []) :: no_return
  def run(%{label: uuid}, []) do
    Farmbot.BotState.ProcessTracker.start_process(uuid)
  end
end
