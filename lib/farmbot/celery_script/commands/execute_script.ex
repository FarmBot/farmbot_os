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
  @spec run(%{label: String.t}, [Command.Pair.t]) :: no_return
  def run(%{label: farmware}, env_vars) do
    Command.set_user_env(%{}, env_vars)
    info = Farmbot.BotState.ProcessTracker.lookup(:farmware, farmware)
    if info do
      Command.start_process(%{label: info.uuid}, [])
    else
      Logger.error ">> Could not locate: #{farmware}"
    end
  end
end
