defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.FirmwareConfig do
  @moduledoc """
  This asset worker does not get restarted. It inistead responds to GenServer
  calls.
  """

  use GenServer
  require FarmbotCore.Logger
  alias FarmbotFirmware
  alias FarmbotCore.{Asset.FirmwareConfig, FirmwareSideEffects}

  def preload(%FirmwareConfig{}), do: []

  def tracks_changes?(%FirmwareConfig{}), do: true

  def start_link(%FirmwareConfig{} = fw_config, _args) do
    GenServer.start_link(__MODULE__, %FirmwareConfig{} = fw_config)
  end

  def init(%FirmwareConfig{} = fw_config) do
    {:ok, %FirmwareConfig{} = fw_config}
  end

  def handle_cast({:new_data, new_fw_config}, old_fw_config) do
    # Generate the changes between the old config and the new one.
    %{changes: changes} = FirmwareConfig.changeset(old_fw_config, Map.from_struct(new_fw_config))
    # Extract only the needed values.
    changes = FirmwareSideEffects.known_params(changes)
    # write each changed parameter, and read it back to set it on the state.
    for {param, value} <- changes, do: do_write_read(param, value)
    # save the new config on the state.
    {:noreply, new_fw_config}
  end

  defp do_write_read(param, value) do
    with :ok <- FarmbotFirmware.command({:parameter_write, [{param, value}]}),
          {:ok, {_, {:report_parameter_value, [{^param, ^value}]}}} <- FarmbotFirmware.request({:parameter_read, [param]}) do
      FarmbotCore.Logger.success 1, "Firmware parameter updated: #{param} #{value}"
      :ok
      else
    {:error, reason} ->
      FarmbotCore.Logger.error 1, "Error writing firmware parameter: #{param}: #{inspect(reason)}"

    {:ok, {_, {:report_parameter_value, [{param, value}]}}} ->
      FarmbotCore.Logger.error 1, "Error writing firmware parameter #{param}: incorrect data reply: #{value}"

    end
  end
end
