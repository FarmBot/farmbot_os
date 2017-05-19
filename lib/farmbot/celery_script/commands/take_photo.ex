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
    i = Farmbot.BotState.ProcessTracker.lookup context, :farmware, "take-photo"
    if i do
      Command.start_process(%{label: i.uuid}, [], context)
    else
      raise "take-photo is not installed!"
    end
  end
end
