defimpl Farmbot.AssetWorker, for: Farmbot.Asset.Device do
  alias Farmbot.Asset.Device
  use GenServer
  import Farmbot.Config, only: [update_config_value: 4]

  def start_link(%Device{} = device) do
    GenServer.start_link(__MODULE__, [%Device{} = device])
  end

  def init([%Device{} = device]) do
    {:ok, %Device{} = device, 0}
  end

  def handle_info(:timeout, %Device{} = device) do
    update_config_value(:string, "settings", "timezone", device.timezone)
    {:noreply, device}
  end
end
