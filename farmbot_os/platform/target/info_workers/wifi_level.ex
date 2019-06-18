defmodule FarmbotOS.Platform.Target.InfoWorker.WifiLevel do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    {:ok, %{}, 0}
  end

  def handle_info(:timeout, state) do
    Logger.warn("Reenable wifi level worker")
    {:noreply, state}
  end
end
