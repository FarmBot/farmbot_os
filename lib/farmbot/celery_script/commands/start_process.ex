defmodule Farmbot.CeleryScript.Command.StartProcess do
  @moduledoc """
    StartProcess
  """

  alias Farmbot.CeleryScript.{Command, Ast}
  @behaviour Command

  @doc ~s"""
    Starts a FarmProcess
      args: %{label: String.t},
      body: []
  """
  @spec run(%{label: String.t}, [], Ast.context) :: Ast.context
  def run(%{label: uuid}, [], context) do
    Farmbot.BotState.ProcessTracker.start_process(context, uuid)
    context
  end
end
