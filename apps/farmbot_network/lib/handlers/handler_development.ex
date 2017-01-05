defmodule Module.concat([Farmbot, Network, Handler, "development"]) do
  @behaviour Farmbot.Network.Handler
  alias Farmbot.Network.Manager
  require Logger

  def manager, do: GenEvent.start_link

  def init(_) do
    Logger.debug ">> development network handler init."
    Manager.connected("lo", "127.0.0.1")
    {:ok, []}
  end

  def handle_call(:ok, state) do
    {:ok, :ok, state}
  end

  def handle_call(:scan, state) do
    {:ok, [], state}
  end
end
