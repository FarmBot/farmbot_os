defmodule Farmbot.CeleryScript.AST.Node.RpcOk do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:label]

  def execute(%{label: _label} = args, body, env) do
    ast = rebuild_self(args, body)
    case Farmbot.BotState.emit(ast) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
