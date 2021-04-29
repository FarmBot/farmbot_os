defmodule FarmbotCore.Firmware.InboundSideEffects do
  @moduledoc """
  """
  alias FarmbotCore.{BotState, FirmwareEstopTimer}
  alias FarmbotCore.Firmware.TxBuffer
  alias FarmbotCore.Asset

  require Logger
  require FarmbotCore.Logger

  def process(state, gcode) do
    # Uncomment this line for debugging:
    Enum.map(gcode, fn
      {:current_position, _} -> nil
      {:emergency_lock, _} -> nil
      {:encoder_position_raw, _} -> nil
      {:encoder_position_scaled, _} -> nil
      {:end_stops_report, _} -> nil
      {:idle, _} -> nil
      {name, values} -> IO.inspect(values, label: "==> #{inspect(name)}")
    end)

    Enum.reduce(gcode, state, &reduce/2)
  end

  defp reduce({:debug_message, string}, state) do
    Logger.debug("Firmware Message: #{inspect(string)}")
    state
  end

  defp reduce({:idle, _}, state) do
    _ = FirmwareEstopTimer.cancel_timer()
    :ok = BotState.set_firmware_unlocked()
    idle()
    TxBuffer.process_next_message(state)
  end

  defp reduce({:complete_homing_x, _}, state), do: homing_done(state, :x)
  defp reduce({:complete_homing_y, _}, state), do: homing_done(state, :y)
  defp reduce({:complete_homing_z, _}, state), do: homing_done(state, :z)

  defp reduce({:axis_state_report, result}, state) do
    map_args(result, fn
      {:x, _} = p -> set_axis_state(p)
      {:y, _} = p -> set_axis_state(p)
      {:z, _} = p -> set_axis_state(p)
      _ -> nil
    end)

    state
  end

  defp reduce({:current_position, %{x: x, y: y, z: z}}, state) do
    :ok = BotState.set_position(x, y, z)
    state
  end

  defp reduce({:encoder_position_raw, %{x: x, y: y, z: z}}, state) do
    :ok = BotState.set_encoders_raw(x, y, z)
    state
  end

  defp reduce({:encoder_position_scaled, %{x: x, y: y, z: z}}, state) do
    :ok = BotState.set_encoders_scaled(x, y, z)
    state
  end

  defp reduce({:end_stops_report, %{z_endstop_a: za, z_endstop_b: za}}, s) do
    :noop
    s
  end

  defp reduce({:calibration_state_report, result}, state) do
    FarmbotCeleryScript.SysCalls.sync()
    Process.sleep(1000)

    result
    |> map_args(fn
      {:x, value} -> {:movement_axis_nr_steps_x, value}
      {:y, value} -> {:movement_axis_nr_steps_y, value}
      {:z, value} -> {:movement_axis_nr_steps_z, value}
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
    |> Asset.update_firmware_config!()
    |> Asset.Private.mark_dirty!(%{})

    state
  end

  defp reduce({:start, %{queue: _}}, state) do
    busy()
    state
  end

  defp reduce({:echo, echo_string}, state) do
    clean_echo = String.replace(echo_string, "*", "")
    next_state = TxBuffer.process_echo(state, clean_echo)

    if echo_string == "*F09*" do
      # INBOUND SIDE EFFECT: The Firmware echoed our unlock back.
      %{next_state | tx_buffer: TxBuffer.new(), locked: false}
    else
      next_state
    end
  end

  defp reduce({:running, _}, state) do
    busy()
    state
  end

  defp reduce({:error, %{queue: q_float}}, state) do
    idle()

    state
    |> TxBuffer.process_error(trunc(q_float))
    |> TxBuffer.process_next_message()
  end

  defp reduce({:invalidation, _}, _), do: raise("FBOS SENT INVALID GCODE")

  defp reduce({:ok, %{queue: q_float}}, state) do
    state
    |> TxBuffer.process_ok(trunc(q_float))
    |> TxBuffer.process_next_message()
  end

  # USECASE I: MCU is not configured. FBOS did not try to
  # upload yet.
  defp reduce({:not_configured, _}, %{config_phase: :not_started} = state) do
    busy()
    FarmbotCore.Firmware.ConfigUploader.upload(state)
  end

  # USECASE II: MCU is not configured, but FBOS already started an upload.
  defp reduce({:not_configured, _}, state) do
    busy()
    state
  end

  defp reduce({:emergency_lock, _}, state) do
    :ok = BotState.set_firmware_locked()
    state
  end

  defp reduce({:param_value_report, %{pin_or_param: p_float, value: v}}, s) do
    FarmbotCore.Firmware.ConfigUploader.verify_param(s, {trunc(p_float), v})
  end

  defp reduce({:software_version, version}, state) do
    :ok = BotState.set_firmware_version(version)
    state
  end

  defp reduce({:pin_value_report, %{pin_or_param: pin, value: value}}, state) do
    BotState.set_pin_value(trunc(pin), value)
    state
  end

  defp reduce({:different_x_coordinate_than_given, _}, s), do: maxed(s, "x")
  defp reduce({:different_y_coordinate_than_given, _}, s), do: maxed(s, "y")
  defp reduce({:different_z_coordinate_than_given, _}, s), do: maxed(s, "z")

  defp reduce(
         {:report_updated_param_during_calibration,
          %{pin_or_param: p, value: v}},
         state
       ) do
    k = FarmbotFirmware.Parameter.translate(trunc(p))

    %{k => v}
    |> Asset.update_firmware_config!()
    |> Asset.Private.mark_dirty!(%{})

    state
  end

  defp reduce({:movement_retry, _}, state) do
    FarmbotCore.Logger.debug(1, "Retrying movement")
    state
  end

  defp reduce(unknown, state) do
    msg = "=== Unhandled inbound side effects: #{inspect(unknown)}"
    FarmbotCore.Logger.info(3, msg)
    state
  end

  defp maxed(state, axis) do
    FarmbotCore.Logger.info(3, "#{axis} stopped at max")
    state
  end

  # Use this when you need to selectively operate on args.
  defp map_args(args, cb), do: args |> Map.to_list() |> Enum.map(cb)

  @axis_states %{
    0.0 => "idle",
    1.0 => "begin",
    2.0 => "accelerate",
    3.0 => "cruise",
    4.0 => "decelerate",
    5.0 => "stop",
    6.0 => "crawl"
  }

  defp set_axis_state({axis, value}) do
    BotState.set_axis_state(axis, Map.get(@axis_states, value))
  end

  defp homing_done(state, _) do
    # Noop
    state
  end

  defp idle() do
    mapper = fn axis -> set_axis_state({axis, 0.0}) end
    Enum.map([:x, :y, :z], mapper)
    :ok = BotState.set_firmware_idle(true)
    :ok = BotState.set_firmware_busy(false)
  end

  defp busy() do
    :ok = BotState.set_firmware_idle(false)
    :ok = BotState.set_firmware_busy(true)
  end
end
