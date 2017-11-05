defmodule Farmbot.CeleryScript.AST.Node.RpcRequest do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.CeleryScript.AST.Node
  allow_args [:label]

  def execute(%{label: label}, body, env) do
    do_reduce(body, label, env)
  end

  defp do_reduce([ast | rest], label, env) do
    case Farmbot.CeleryScript.execute(ast, env) do
      {:ok, new_env} -> do_reduce(rest, label, new_env)
      {:error, reason, new_env} -> handle_error(ast, reason, new_env)
    end
  end

  defp do_reduce([], label, env) do
    Node.RpcOk.execute(%{label: label}, [], env)
  end

  defp handle_error(ast, reason, env) do
    case Node.Explanation.execute(%{message: "#{inspect ast} failed: #{inspect reason}"}, [], env) do
      {:ok, expl, new_env} -> Node.RpcError.execute(%{label: ast.args.label}, [expl], new_env)
      {:error, reason, env} -> {:error, reason, env}
    end
  end
end
