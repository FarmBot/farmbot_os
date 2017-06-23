defmodule Farmbot.CeleryScript.Command.SetUserEnv do
  @moduledoc """
    SetUserEnv
  """

  alias      Farmbot.CeleryScript.{Command, Types}
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    Sets a bunch of user environment variables for farmware
      args: %{},
      body: [pair]
  """
  @spec run(%{}, Types.pairs, Context.t) :: Context.t
  def run(%{}, env_pairs, context) do
     envs = Command.pairs_to_tuples(env_pairs)
     map = envs |> Map.new
     Farmbot.BotState.set_user_env(context, map)
     context
  end
end
