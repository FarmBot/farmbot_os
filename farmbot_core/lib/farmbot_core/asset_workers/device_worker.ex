defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.Device do
  alias FarmbotCore.Asset.Device
  use GenServer
  require FarmbotCore.Logger

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

  def handle_cast({:new_data, new_device}, old_device) do
    _ = log_changes(new_device, old_device)
    {:noreply, new_device}
  end

  def log_changes(new_device, old_device) do
    interesting_params = [
      :ota_hour
    ]
    new_interesting_device = Map.take(new_device, interesting_params) |> MapSet.new()
    old_interesting_device = Map.take(old_device, interesting_params) |> MapSet.new()
    difference = MapSet.difference(new_interesting_device, old_interesting_device)
    Enum.each(difference, fn
      {:ota_hour, nil} ->
        FarmbotCore.Logger.success 1, "Farmbot will apply updates as soon as possible"
      {:ota_hour, hour} ->
        FarmbotCore.Logger.success 1, "Farmbot will apply updates at #{hour}"

      {_key, _value} ->
        :noop
    end)
  end
end
