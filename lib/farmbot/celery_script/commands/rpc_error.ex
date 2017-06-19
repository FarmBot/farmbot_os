defmodule Farmbot.CeleryScript.Command.RpcError do
  @moduledoc """
    RpcError
  """

  alias      Farmbot.CeleryScript.{Ast, Command, Types}
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    bad return for a valid Rpc Request
      args: %{label: String.t},
      body: [Explanation]
  """
  @spec run(%{label: binary}, [Types.explanation_ast], Context.t) :: Context.t
  def run(%{label: id}, explanations, context) do
    item = %Ast{kind: "rpc_error", args: %{label: id}, body: explanations}
    Farmbot.Context.push_data(context, item)
  end
end
