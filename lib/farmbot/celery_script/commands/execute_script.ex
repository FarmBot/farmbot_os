defmodule Farmbot.CeleryScript.Command.ExecuteScript do
  @moduledoc """
    ExecuteScript
  """

  alias Farmbot.CeleryScript.{Command, Error, Types}
  alias Farmbot.Farmware
  alias Farmware.{Manager, Runtime}
  import Farmbot.Lib.Helpers
  @behaviour Command

  @doc ~s"""
    Executes a farmware
      args: %{label: uuid},
      body: [pair]
  """
  @spec run(%{label: binary}, Types.pairs, Context.t) :: Context.t | no_return
  def run(%{label: uuid}, env_vars, context) when is_uuid(uuid) do
    new_context = Command.set_user_env(%{}, env_vars, context)
    case Manager.lookup(context, uuid) do
      {:ok, %Farmware{} = fw} -> Runtime.execute(new_context, fw)
      {:error, e}             ->
        raise Error,
          message: "Could not locate farmware: #{e}",
          context: new_context
    end
  end

  def run(%{label: not_uuid}, _, context) do
    raise Error, context: context,
      message: "Expected a uuid but got: #{inspect not_uuid}"
  end
end
