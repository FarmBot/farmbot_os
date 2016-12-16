defmodule Module.concat([Farmbot, Network, Handler, "development"]) do
  @behaviour Farmbot.Network.Handler
  require Logger
  def manager, do: GenEvent.start_link
  def init({parent, _config}) do
    Logger.debug ">> development network handler init."
    GenServer.cast parent, {:connected, "lo", "127.0.0.1"}
    {:ok, parent}
  end
end
