defmodule Farmbot.Farmware.Runtime do
  @moduledoc """
    Executes a farmware
  """
  use Farmbot.DebugLog
  alias Farmbot.{Farmware, Context, BotState, Auth}
  alias Farmware.RuntimeError, as: FarmwareRuntimeError

  @doc """
    Executes a Farmware inside a safe sandbox
  """
  def execute(%Context{} = ctx, %Farmware{} = fw) do
    debug_log "Starting execution of #{inspect fw}"
    env = environment(ctx)
    
  end

  defp environment(%Context{} = ctx) do
    envs = BotState.get_user_env(ctx)
    {:ok, %Farmbot.Token{} = tkn} = Auth.get_token(ctx.auth)
    envs = Map.put(envs, "API_TOKEN", tkn)
    Enum.map(envs, fn({key, val}) ->
      {to_erl_safe(key), to_erl_safe(val)}
    end)
  end

  defp to_erl_safe(%Farmbot.Token{encoded: enc}), do: to_erl_safe(enc)
  defp to_erl_safe(binary) when is_binary(binary), do: to_charlist(binary)
  defp to_erl_safe(map) when is_map(map), do: map |> Poison.encode! |> to_erl_safe()
end
