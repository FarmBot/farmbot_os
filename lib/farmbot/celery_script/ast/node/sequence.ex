defmodule Farmbot.CeleryScript.AST.Node.Sequence do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:version, :is_outdated]

  def execute(%{version: _, is_outdated: _}, body, env) do
    do_reduce(body, env)
  end

  defp do_reduce([ast | rest], env) do
    case Farmbot.CeleryScript.execute(ast) do
      {:ok, new_env} -> do_reduce(rest, new_env)
      {:error, reason, env} -> {:error, reason, env}
    end
  end
end
