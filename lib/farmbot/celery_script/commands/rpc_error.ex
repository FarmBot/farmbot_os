defmodule Farmbot.CeleryScript.Command.RpcError do
  @moduledoc """
    RpcError
  """

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    bad return for a valid Rpc Request
      args: %{label: String.t},
      body: [Explanation]
  """
  @spec run(%{label: String.t},
    [Command.explanation_type], Ast.context) :: Ast.context
  def run(%{label: id}, explanations, context) do
    item = %Ast{kind: "rpc_error", args: %{label: id}, body: explanations}
    Ast.Context.push_data(context, item)
  end
end
