defmodule Farmbot.Auth.Subscription do
  @moduledoc """
    Farmbot Auth Registry implementation.
  """

  use GenServer
  use Farmbot.DebugLog
  alias Farmbot.CeleryScript.Ast.Context

  def start_link(%Context{} = context, opts \\ []) do
    GenServer.start_link(__MODULE__, context, opts)
  end

  def init(%Context{} = context) do
    Registry.register(Farmbot.Registry, Farmbot.Auth, [])
    {:ok, %{context: context, token: nil}}
  end

  def handle_info({Farmbot.Auth, {:error, :bad_password}}, state) do
    get_new(state.context)
    {:noreply, %{state | token: nil}}
  end

  def handle_info({Farmbot.Auth, {:error, :expired_token}}, state) do
    get_new(state.context)
    {:noreply, %{state | token: nil}}
  end

  def handle_info({Farmbot.Auth, {:new_token, token}}, state) do
    {:noreply, %{state | token: token}}
  end

  def handle_info({Farmbot.Auth, :purge_token}, state), do: {:noreply, %{state | token: nil}}

  def handle_info({Farmbot.Auth, message}, state) do
    debug_log "unhandled auth message: #{inspect message}"
    {:noreply, state}
  end

  defp get_new(%Context{} = context) do
    spawn fn ->
      Farmbot.Auth.try_log_in!(context.auth)
    end
  end
end
