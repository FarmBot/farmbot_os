defmodule Farmbot.Repo.AfterSyncWorker do
  use GenServer
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    Farmbot.Repo.Registry.subscribe()
    {:ok, %{}}
  end

  def handle_info({Farmbot.Repo.Registry, _action, Farmbot.Asset.Device, data}, state) do
    Farmbot.System.ConfigStorage.update_config_value(:string, "settings", "timezone", data.timezone)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
