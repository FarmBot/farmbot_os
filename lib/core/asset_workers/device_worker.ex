defimpl FarmbotOS.AssetWorker, for: FarmbotOS.Asset.Device do
  alias FarmbotOS.Asset.Device
  use GenServer
  require FarmbotOS.Logger

  def tracks_changes?(%Device{}), do: true

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

  def handle_info({:csvm_done, _ref, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:new_data, new_device}, _old_dev) do
    {:noreply, new_device}
  end
end
