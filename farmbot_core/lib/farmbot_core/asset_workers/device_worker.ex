defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.Device do
  alias FarmbotCore.{Asset, Asset.Device}
  alias FarmbotCeleryScript.AST
  use GenServer
  require FarmbotCore.Logger

  def tracks_changes?(%Device{}), do: true

  def preload(%Device{}), do: []

  def start_link(%Device{} = device, _args) do
    GenServer.start_link(__MODULE__, %Device{} = device)
  end

  def init(%Device{} = device) do
    send(self(), :check_factory_reset)
    {:ok, %Device{} = device, 0}
  end

  def handle_info(:timeout, %Device{} = device) do
    {:noreply, device}
  end

  def handle_info(:check_factory_reset, %Device{needs_reset: true} = state) do
    ast =
      AST.Factory.new()
      |> AST.Factory.rpc_request("RESET_DEVICE_NOW")
      |> AST.Factory.factory_reset("farmbot_os")

    :ok = FarmbotCeleryScript.execute(ast, make_ref())

    {:noreply, state}
  end

  def handle_info(:check_factory_reset, state) do
    {:noreply, state}
  end

  def handle_info({:csvm_done, _ref, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:new_data, new_device}, old_device) do
    _ = log_changes(new_device, old_device)
    send(self(), :check_factory_reset)
    {:noreply, new_device}
  end

  def log_changes(new_device, old_device) do
    interesting_params = [
      :ota_hour,
      :mounted_tool_id
    ]

    new_interesting_device = Map.take(new_device, interesting_params) |> MapSet.new()
    old_interesting_device = Map.take(old_device, interesting_params) |> MapSet.new()
    difference = MapSet.difference(new_interesting_device, old_interesting_device)

    Enum.each(difference, fn
      {:ota_hour, nil} ->
        FarmbotCore.Logger.success(1, "Farmbot will apply updates as soon as possible")

      {:ota_hour, hour} ->
        FarmbotCore.Logger.success(1, "Farmbot will apply updates during the hour of #{hour}:00")

      {:mounted_tool_id, nil} ->
        if old_device.mounted_tool_id do
          if tool = Asset.get_tool(id: old_device.mounted_tool_id) do
            FarmbotCore.Logger.info(2, "Dismounted the #{tool.name}")
          else
            FarmbotCore.Logger.info(2, "Dismounted unknown tool")
          end
        else
          # no previously mounted tool
          :ok
        end

      {:mounted_tool_id, id} ->
        if tool = Asset.get_tool(id: id) do
          FarmbotCore.Logger.info(2, "Mounted the #{tool.name}")
        else
          FarmbotCore.Logger.info(2, "Mounted unknown tool")
        end

      {_key, _value} ->
        :noop
    end)
  end
end
