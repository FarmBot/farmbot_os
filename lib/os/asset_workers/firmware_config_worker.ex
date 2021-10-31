defimpl FarmbotOS.AssetWorker, for: FarmbotOS.Asset.FirmwareConfig do
  @moduledoc """
  This asset worker does not get restarted. It instead responds to GenServer
  calls.
  """

  use GenServer
  require FarmbotOS.Logger
  alias FarmbotOS.Asset.FirmwareConfig

  def preload(%FirmwareConfig{}), do: []

  def tracks_changes?(%FirmwareConfig{}), do: true

  def start_link(%FirmwareConfig{} = fw_config, _args) do
    GenServer.start_link(__MODULE__, %FirmwareConfig{} = fw_config)
  end

  def init(%FirmwareConfig{} = fw_config) do
    {:ok, %FirmwareConfig{} = fw_config}
  end

  def handle_cast({:new_data, new_fw_config}, _old_fw_config) do
    FarmbotOS.Firmware.UARTObserver.data_available(__MODULE__)
    {:noreply, new_fw_config}
  end
end
