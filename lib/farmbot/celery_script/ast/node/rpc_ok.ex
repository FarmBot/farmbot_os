defmodule Farmbot.CeleryScript.AST.Node.RpcOk do
  @moduledoc false

  # credo:disable-for-this-file

  use Farmbot.CeleryScript.AST.Node
  allow_args [:label]

  def execute(%{label: _label} = args, body, env) do
    env = mutate_env(env)
    ast = rebuild_self(args, body)
    case Farmbot.BotState.emit(ast) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
