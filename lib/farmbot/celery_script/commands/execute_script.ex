defmodule Farmbot.CeleryScript.Command.ExecuteScript do
  @moduledoc """
    ExecuteScript
  """

  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Executes a farmware
      args: %{label: String.t},
      body: [pair]
    NOTE this is a shortcut to starting a process by uuid
  """
  @spec run(%{label: String.t}, [Command.Pair.t], Ast.context) :: Ast.context
  def run(%{label: farmware}, env_vars, context) do
    Command.set_user_env(%{}, env_vars, context)
    info = Farmbot.BotState.ProcessTracker.lookup(context, :farmware, farmware)
    if info do
      Command.start_process(%{label: info.uuid}, [], context)
    else
      Logger.error ">> Could not locate: #{farmware}"
    end
    context
  end
end
