defimpl Farmbot.AssetWorker, for: Farmbot.Asset.Device do
  alias Farmbot.Asset.Device
  use GenServer

  def preload(%Device{}), do: []

  def start_link(%Device{} = device, _args) do
    GenServer.start_link(__MODULE__, %Device{} = device)
  end

  def init(%Device{} = device) do
    {:ok, %Device{} = device, 0}
  end

  def handle_info(:timeout, %Device{} = device) do
    {:noreply, device}
  end
end
