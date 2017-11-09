defmodule Farmbot.CeleryScript.AST.Node.SetUserEnv do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []
  use Farmbot.Logger

  def execute(_args, body, env) do
    env = mutate_env(env)
    do_reduce(body, env)
  end

  defp do_reduce([%{args: %{label: key, value: val}} | rest], env) do
    case Farmbot.BotState.set_user_env(key, val) do
      :ok -> do_reduce(rest, env)
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_reduce([], env), do: {:ok, env}
end
