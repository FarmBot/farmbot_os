defmodule Farmbot.CeleryScript.Command.ExecuteScript do
  @moduledoc """
    ExecuteScript
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Farmware
  alias Farmware.{Manager, Runtime}
  @behaviour Command

  @doc ~s"""
    Executes a farmware
      args: %{label: uuid},
      body: [pair]
  """
  @spec run(%{label: binary}, [Command.Pair.t], Ast.context) :: Ast.context
  def run(%{label: uuid}, env_vars, context) do
    Command.set_user_env(%{}, env_vars, context)
    case Manager.lookup(context, uuid) do
      {:ok, %Farmware{} = fw} -> Runtime.execute(context, fw)
      {:error, e}             -> raise "Could not locate farmware: #{e}"
    end
  end
end
