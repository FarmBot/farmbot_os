defmodule FarmbotOS.Firmware.ConfigUploader do
  alias FarmbotOS.Asset
  alias FarmbotOS.BotState

  alias FarmbotOS.Firmware.{
    GCode,
    Parameter,
    TxBuffer
  }

  require Logger
  require FarmbotOS.Logger

  # Called at runtime when FirmwareConfig value(s) change.
  def refresh(state, new_keys) do
    conf = maybe_get_config()

    if conf do
      new_data = Map.take(conf, new_keys)
      msg = "Updating firmware parameters: #{inspect(new_keys)}"
      FarmbotOS.Logger.info(3, msg)
      %{state | tx_buffer: write_configs(new_data, state)}
    else
      state
    end
  end

  # Called right after firmware init.
  def upload(state) do
    Process.sleep(3000)
    do_upload(state, maybe_get_config())
  end

  def maybe_get_config() do
    data = fw_config()

    missing_key? =
      data
      |> Map.to_list()
      |> Enum.find(fn
        {key, nil} ->
          Logger.debug("FW Config #{inspect(key)} is nil")
          key

        {_, _} ->
          false
      end)

    if missing_key? do
      nil
    else
      data
    end
  end

  def verify_param(state, {param_code, value}) do
    do_verify_param(maybe_get_config(), {param_code, value})
    state
  end

  @ignored_params [0, 1, 2, 3]

  defp do_verify_param(_, {p, _}) when p in @ignored_params, do: nil
  defp do_verify_param(nil, _conf), do: nil

  defp do_verify_param(conf, {p, actual}) do
    key = Parameter.translate(p)
    expected = Map.fetch!(conf, key)

    if actual == expected do
      :ok = BotState.set_firmware_config(key, actual)
    end
  end

  defp do_upload(state, nil), do: state

  defp do_upload(state, config_data) do
    next_tx_buffer =
      config_data
      |> write_configs(state)
      # Approve configuration
      |> TxBuffer.push(nil, GCode.new(:F22, P: 2, V: 1))
      # Request software version
      |> TxBuffer.push(nil, GCode.new(:F83, []))
      |> maybe_home_at_boot(config_data)

    %{state | tx_buffer: next_tx_buffer, needs_config: false}
  end

  defp fw_config do
    Map.take(Asset.firmware_config(), Parameter.names())
  end

  defp write_configs(config_data, state) do
    config_data
    |> Map.to_list()
    |> Enum.filter(fn {k, _v} -> Parameter.is_param?(k) end)
    |> Enum.map(fn {key, value} -> {Parameter.translate(key), value} end)
    |> Enum.map(fn {p, v} ->
      # Crash on bad input:
      _ = Parameter.translate(p)
      GCode.new(:F22, P: p, V: v)
    end)
    |> Enum.reduce(state.tx_buffer, fn gcode, tx_buffer ->
      TxBuffer.push(tx_buffer, nil, gcode)
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
        FarmbotOS.Logger.debug(3, "Finding home on x")
        TxBuffer.push(tx_buffer, nil, GCode.new(:F11, []))

      :y, tx_buffer ->
        FarmbotOS.Logger.debug(3, "Finding home on y")
        TxBuffer.push(tx_buffer, nil, GCode.new(:F12, []))

      :z, tx_buffer ->
        FarmbotOS.Logger.debug(3, "Finding home on z")
        TxBuffer.push(tx_buffer, nil, GCode.new(:F13, []))
    end)
  end
end
