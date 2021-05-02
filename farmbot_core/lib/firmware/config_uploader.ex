defmodule FarmbotCore.Firmware.ConfigUploader do
  alias FarmbotCore.Asset
  alias FarmbotCore.BotState
  alias FarmbotCore.Firmware.{Command, TxBuffer}
  alias FarmbotFirmware.Parameter

  require Logger
  require FarmbotCore.Logger

  # Called at runtime when FirmwareConfig value(s) change.
  def refresh(state, new_keys) do
    conf = maybe_get_config()

    if conf do
      new_data = Map.take(conf, new_keys)
      msg = "Updating firmware parameters: #{inspect(new_keys)}"
      FarmbotCore.Logger.info(3, msg)
      %{state | tx_buffer: write_configs(new_data, state)}
    else
      state
    end
  end

  # Called right after firmware init.
  def upload(state) do
    FarmbotCeleryScript.SysCalls.sync()
    Process.sleep(1000)
    %{do_upload(state, maybe_get_config()) | locked: false}
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
      FarmbotCore.Logger.debug(
        3,
        "Some configs nil; Can't send FW configuration."
      )

      nil
    else
      data
    end
  end

  def verify_param(state, {param_code, value}) do
    do_verify_param(maybe_get_config(), {param_code, value})
    state
  end

  defp do_verify_param(_, {2, _}) do
    FarmbotCore.Logger.debug(3, "Done sending firmware parameters")
  end

  defp do_verify_param(nil, _conf) do
  end

  defp do_verify_param(conf, {p, actual}) do
    key = Parameter.translate(p)
    expected = Map.fetch!(conf, key)

    unless actual == expected do
      a = inspect(actual)
      e = inspect(expected)
      k = inspect(key)
      raise "Expected #{k} to eq #{e}. Got: #{a}"
    else
      :ok = BotState.set_firmware_config(key, actual)
    end
  end

  defp do_upload(state, nil), do: state

  defp do_upload(state, config_data) do
    FarmbotCore.Logger.debug(3, "Sending parameters to firmware")

    next_tx_buffer =
      config_data
      |> write_configs(state)
      # Approve configuration
      |> TxBuffer.push({nil, "F22 P2 V1"})
      # Request software version
      |> TxBuffer.push({nil, "F83"})
      |> maybe_home_at_boot(config_data)

    %{state | tx_buffer: next_tx_buffer, config_phase: :sent}
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

  defp write_configs(config_data, state) do
    config_data
    |> Map.to_list()
    |> Enum.filter(fn {k, _v} -> Parameter.is_param?(k) end)
    |> Enum.map(fn {key, value} -> {Parameter.translate(key), value} end)
    |> Enum.map(&Command.f22/1)
    |> Enum.reduce(state.tx_buffer, fn gcode, tx_buffer ->
      TxBuffer.push(tx_buffer, {nil, gcode})
    end)
  end

  defp maybe_home_at_boot(txb, conf) do
    conf
    |> Enum.map(fn
      {:movement_home_at_boot_x, 1.0} -> :x
      {:movement_home_at_boot_y, 1.0} -> :y
      {:movement_home_at_boot_z, 1.0} -> :z
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.reduce(txb, fn
      :x, tx_buffer ->
        FarmbotCore.Logger.debug(3, "=== Finding home on x")
        TxBuffer.push(tx_buffer, {nil, "F11"})

      :y, tx_buffer ->
        FarmbotCore.Logger.debug(3, "=== Finding home on y")
        TxBuffer.push(tx_buffer, {nil, "F12"})

      :z, tx_buffer ->
        FarmbotCore.Logger.debug(3, "=== Finding home on z")
        TxBuffer.push(tx_buffer, {nil, "F13"})
    end)
  end
end
