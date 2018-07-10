defmodule Farmbot.Repo.AfterSyncWorker do
  @moduledoc false

  use GenServer
  use Farmbot.Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    Farmbot.Repo.Registry.subscribe()
    Farmbot.PinBinding.Manager.confirm_asset_storage_up()
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

  def handle_info({Farmbot.Repo.Registry, :addition, Farmbot.Asset.PinBinding, %{pin_num: pin, sequence_id: sequence_id}}, state) do
    Farmbot.PinBinding.Manager.register_pin(pin, sequence_id)
    {:noreply, state}
  end

  def handle_info({Farmbot.Repo.Registry, :updated, Farmbot.Asset.PinBinding, %{pin_num: pin, sequence_id: sequence_id}}, state) do
    Farmbot.PinBinding.Manager.unregister_pin(pin)
    Farmbot.PinBinding.Manager.register_pin(pin, sequence_id)
    {:noreply, state}
  end

  def handle_info({Farmbot.Repo.Registry, :deletion, Farmbot.Asset.PinBinding, %{pin_num: pin, sequence_id: _sequence_id}}, state) do
    Farmbot.PinBinding.Manager.unregister_pin(pin)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
