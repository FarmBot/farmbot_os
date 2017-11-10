defmodule Farmbot.CeleryScript do
  @moduledoc """
  CeleryScript is the scripting language that Farmbot OS understands.
  """

  alias Farmbot.CeleryScript.AST
  use Farmbot.Logger

  @doc "Execute an AST node."
  def execute(ast, env \\ struct(Macro.Env))

  def execute(%AST{kind: kind, body: body, args: args} = ast, env) do
    # Logger.busy 3, "doing: #{inspect ast}"
    maybe_log_comment(ast)
    case kind.execute(args, body, env) do
      {:ok, %Macro.Env{} = _env} = res -> res
      {:ok, %AST{} = ast} -> execute(ast, env)
      {:error, reason, env} ->
        Logger.error 2, "CS Failed: #{env.module} - #{inspect reason}"
        {:error, reason, env}
    end
  end

  defp maybe_log_comment(%{comment: nil}), do: :ok
  defp maybe_log_comment(%AST{comment: comment} = _ast) do
    Logger.info 2, "[#{comment.kind}] - #{comment}"
  end

end
