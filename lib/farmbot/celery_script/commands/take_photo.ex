defmodule Farmbot.CeleryScript.Command.TakePhoto do
  @moduledoc """
    TestCs
  """

  # alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.{Command, Ast}
  require Logger
  @behaviour Command

  @doc ~s"""
    Takes a photo
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    info = Farmbot.BotState.ProcessTracker.lookup :farmware, "take-photo"
    if info do
      Command.start_process(%{label: info.uuid}, [], context)
    else
      raise "take-photo is not installed!"
    end
  end
end
