defmodule Farmbot.CeleryScript.Command.SetUserEnv do
  @moduledoc """
    SetUserEnv
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    Sets a bunch of user environment variables for farmware
      args: %{},
      body: [pair]
  """
  @spec run(%{}, [Command.Pair.t]) :: no_return
  def run(%{}, env_pairs) do
     envs = Command.pairs_to_tuples(env_pairs)
     envs
     |> Map.new
     |> Farmbot.BotState.set_user_env

     envs
     |> Map.new
     |> Farmware.Worker.add_envs
  end
end
