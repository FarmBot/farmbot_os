defmodule Farmbot.CeleryScript.AST.Node.Sequence do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  import Farmbot.System.ConfigStorage, only: [get_config_value: 3]
  allow_args [:version, :label, :locals, :is_outdated]

  def execute(%{label: name}, body, env) do
    if get_config_value(:bool, "settings", "sequence_init_log") do
      Logger.busy 2, "[#{name}] - Sequence init."
    end
    env = mutate_env(env)
    if Farmbot.BotState.locked? do
      {:error, :locked, env}
    else
      do_reduce(body, env, name)
    end
  end

  defp do_reduce([ast | rest], env, name) do
    if get_config_value(:bool, "settings", "sequence_body_log") do
      Logger.info 2, "[#{name}] - Sequence Executing: #{inspect ast}"
    end
    case Farmbot.CeleryScript.execute(ast, env) do
      {:ok, new_env} -> do_reduce(rest, new_env, name)
      {:error, reason, env} ->
        case Farmbot.Firmware.emergency_lock() do
          :ok -> :ok
          {:error, :emergency_lock} -> :ok
          {:error, reason} ->
            Logger.error 1, "Failed to lock the firmware! #{inspect reason}"
        end
        {:error, reason, env}
    end
  end

  defp do_reduce([], env, name) do
    if get_config_value(:bool, "settings", "sequence_complete_log") do
      Logger.success 2, "[#{name}] - Sequence complete."
    end
    {:ok, env}
  end
end
