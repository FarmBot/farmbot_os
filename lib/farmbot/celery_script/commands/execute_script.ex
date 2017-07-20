defmodule Farmbot.CeleryScript.Command.ExecuteScript do
  @moduledoc """
    ExecuteScript
  """

  alias   Farmbot.CeleryScript.{Command, Error, Types}
  alias   Farmbot.Farmware
  alias   Farmware.{Manager, Runtime}
  import  Farmbot.Lib.Helpers
  require Logger
  @behaviour Command

  @doc ~s"""
    Executes a farmware
      args: %{label: uuid or name},
      body: [pair]
  """
  @spec run(%{label: binary}, Types.pairs, Context.t) :: Context.t | no_return
  def run(%{label: uuid}, env_vars, context) when is_uuid(uuid) do
    new_context = Command.set_user_env(%{}, env_vars, context)
    case Manager.lookup(context, uuid) do
      {:ok, %Farmware{} = fw} ->
        Logger.debug ">> Starting Farmware: #{fw.name}", type: :busy
        Runtime.execute(new_context, fw)
      {:error, e}             ->
        raise Error, context: new_context,
          message: "Could not locate farmware: #{e}"
    end
  end

  def run(%{label: not_uuid}, envs, context) when is_binary(not_uuid) do
    case Manager.lookup_by_name(context, not_uuid) do
      {:ok, fw}    -> run(%{label: fw.uuid}, envs, context)
      {:error, _e} ->
        raise Error, context: context,
          message: "Could not locate farmware by name: #{not_uuid}"
    end
  end
end
