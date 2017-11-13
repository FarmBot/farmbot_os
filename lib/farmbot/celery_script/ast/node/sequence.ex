defmodule Farmbot.CeleryScript.AST.Node.Sequence do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  allow_args [:version, :is_outdated]

  def execute(%{version: _, is_outdated: _}, body, env) do
    env = mutate_env(env)
    do_reduce(body, env)
  end

  defp do_reduce([ast | rest], env) do
    case Farmbot.CeleryScript.execute(ast, env) do
      {:ok, new_env} -> do_reduce(rest, new_env)
      {:error, reason, env} -> {:error, reason, env}
    end
  end

  defp do_reduce([], env) do
    Logger.success(2, "Sequence complete!")
    {:ok, env}
  end
end
