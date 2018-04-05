defmodule Farmbot.Repo.AfterSyncWorker do
  @moduledoc false

  use GenServer
  use Farmbot.Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    Farmbot.Repo.Registry.subscribe()
    Farmbot.System.GPIO.confirm_asset_storage_up()
    {:ok, %{}}
  end

  def handle_info({Farmbot.Repo.Registry, _action, Farmbot.Asset.Device, data}, state) do
    Farmbot.System.ConfigStorage.update_config_value(:string, "settings", "timezone", data.timezone)
    {:noreply, state}
  end

  def handle_info({Farmbot.Repo.Registry, action, Farmbot.Asset.Peripheral, %{mode: mode, pin: pin}}, state) when action in [:addition, :updated] do
    mode = if mode == 0, do: :digital, else: :analog
    Logger.busy 3, "Read peripheral (#{pin} - #{mode})"
    Farmbot.Firmware.read_pin(pin, mode)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
