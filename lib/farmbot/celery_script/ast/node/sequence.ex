defmodule Farmbot.CeleryScript.AST.Node.Sequence do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  allow_args [:version, :is_outdated, :label]

  def execute(%{version: _, is_outdated: _, label: name}, body, env) do
    Logger.busy 2, "[#{name}] - Sequence init."
    env = mutate_env(env)
    if Farmbot.BotState.locked? do
      Logger.error 1, "[#{name}] - Sequence failed. Bot is locked!"
      {:error, :locked, env}
    else
      do_reduce(body, env, name)
    end
  end

  defp do_reduce([ast | rest], env, name) do
    Logger.info 2, "[#{name}] - Sequence Executing: #{inspect ast}"
    case Farmbot.CeleryScript.execute(ast, env) do
      {:ok, new_env} -> do_reduce(rest, new_env, name)
      {:error, reason, env} ->
        Logger.warn 1, "[#{name}] - Sequence failed. Locking bot!"
        case Farmbot.Firmware.emergency_lock() do
          :ok -> :ok
          {:error, :emergency_lock} -> :ok
          {:error, reason} -> Logger.error 1, "Failed to lock the firmware! #{inspect reason}"
        end
        {:error, reason, env}
    end
  end

  defp do_reduce([], env, name) do
    Logger.success 2, "[#{name}] - Sequence complete."
    {:ok, env}
  end
end
