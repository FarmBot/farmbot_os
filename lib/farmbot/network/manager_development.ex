defmodule Module.concat([Farmbot, Network, Handler, "development"]) do
  @behaviour Farmbot.Network.Handler
  require Logger
  def manager, do: GenEvent.start_link
  def init({parent, config}) do
    Logger.debug ">> development network handler init."
    Process.send_after(parent, :connected, 1_000)
    {:ok, parent}
  end
end
