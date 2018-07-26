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
      {:error, reason, new_env} -> handle_error(ast, label, reason, new_env)
    end
  end

  defp do_reduce([], label, env) do
    Node.RpcOk.execute(%{label: label}, [], env)
  end

  defp handle_error(ast, label, reason, env) do
    args = %{message: "#{inspect ast} failed: #{inspect reason}"}
    {:ok, expl, new_env} = Node.Explanation.execute(args, [], env)
    Node.RpcError.execute(%{label: label}, [expl], new_env)
  end
end
