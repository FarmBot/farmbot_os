defmodule Farmbot.Auth.Subscription do
  @moduledoc """
    Farmbot Auth Registry implementation.
  """

  use GenServer
  use Farmbot.DebugLog

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    Registry.register(Farmbot.Registry, Farmbot.Auth, [])
    {:ok, nil}
  end

  def handle_info({Farmbot.Auth, {:new_token, token}}, _) do
    {:noreply, token}
  end

  def handle_info({Farmbot.Auth, message}, state) do
    debug_log "unhandled auth message: #{inspect message}"
    {:noreply, state}
  end
end
