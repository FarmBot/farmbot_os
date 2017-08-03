defmodule Farmbot.CeleryScript.Command.ExecuteScript do
  @moduledoc """
    ExecuteScript
  """

  alias   Farmbot.CeleryScript.{Command, Error, Types}
  alias   Farmbot.Farmware
  alias   Farmware.{Manager, Runtime}
  require Logger
  @behaviour Command

  @doc ~s"""
    Executes a farmware
      args: %{label: name},
      body: [pair]
  """
  @spec run(%{label: binary}, Types.pairs, Context.t) :: Context.t | no_return
  def run(%{label: name}, env_vars, context)  do
    new_context = Command.set_user_env(%{}, env_vars, context)
    case Manager.lookup_by_name(context, name) do
      {:ok, %Farmware{} = fw} ->
        Logger.debug ">> Starting Farmware: #{fw.name}", type: :busy
        Runtime.execute(new_context, fw)
      {:error, e}             ->
        raise Error, context: new_context,
          message: "Could not locate farmware: #{e}"
    end
  end
end
