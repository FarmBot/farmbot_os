defmodule Farmbot.CeleryScript.Command.ReadStatus do
  @moduledoc """
    ReadStatus
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    Do a ReadStatus
      args: %{},
      body: []
  """
  @spec run(%{}, []) :: no_return
  def run(%{}, []) do
    Farmbot.BotState.Monitor.get_state
  end
end
