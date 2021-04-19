defmodule FarmbotCore.Firmware.ConfigUploader do
  alias FarmbotCore.Asset
  alias FarmbotFirmware.Parameter
  alias FarmbotCore.Firmware.Command
  alias FarmbotCore.Firmware.TxBuffer

  def upload(state) do
    %{} = do_upload(state, maybe_get_config())
  end

  def maybe_get_config() do
    data = fetch_data()

    missing_key? =
      data
      |> Map.to_list()
      |> Enum.find(fn
        {key, nil} -> key
        {_, _} -> false
      end)

    if missing_key? do
      nil
    else
      data
    end
  end

  defp do_upload(state, nil), do: state

  defp do_upload(state, config_data) do
    next_tx_buffer =
      config_data
      |> Map.to_list()
      |> Enum.filter(fn {k, _v} -> Parameter.is_param?(k) end)
      |> Enum.map(fn {key, value} -> {Parameter.translate(key), value} end)
      |> Enum.map(&Command.f22/1)
      |> Enum.reduce(state.tx_buffer, fn gcode, tx_buffer ->
        TxBuffer.push(tx_buffer, {nil, gcode})
      end)

    %{state | tx_buffer: next_tx_buffer, config_phase: :in_progress}
  end

  defp fetch_data() do
    %{} |> Map.merge(fbos_config()) |> Map.merge(fw_config())
  end

  defp fbos_config do
    keys = [:firmware_hardware, :firmware_path]
    Map.take(Asset.fbos_config(), keys)
  end

  defp fw_config do
    Map.take(Asset.firmware_config(), Parameter.names())
  end
end
