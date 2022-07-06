defmodule FarmbotOS.Firmware.InboundSideEffects do
  @moduledoc """
  """
  alias FarmbotOS.{
    Asset,
    BotState,
    Firmware.GCode,
    Firmware.TxBuffer,
    Firmware.UARTCoreSupport,
    FirmwareEstopTimer,
    Leds
  }

  require Logger
  require FarmbotOS.Logger

  def process(state, gcode_list) do
    # Spawn() so that LED problems don't cause FW Handler to
    # hang or crash
    red_led_pid =
      unless UARTCoreSupport.locked?() do
        unless is_pid(state.red_led_pid) do
          spawn(Leds, :red, [:solid])
        else
          state.red_led_pid
        end
      end

    if state.logs_enabled do
      reject = [
        :current_position,
        :idle,
        :encoder_position_raw,
        :encoder_position_scaled,
        :end_stops_report
      ]

      gcode_list
      |> Enum.map(fn {k, _v} = gcode ->
        unless Enum.member?(reject, k) do
          Logger.debug(inspect(gcode))
        end
      end)
    end

    state = Enum.reduce(gcode_list, state, &reduce/2)
    %{state | rx_count: state.rx_count + 1, red_led_pid: red_led_pid}
  end

  defp reduce({:debug_message, string}, state) do
    Logger.info("Firmware Message: " <> string)
    state
  end

  defp reduce({:idle, _}, state) do
    _ = FirmwareEstopTimer.cancel_timer()
    :ok = BotState.set_firmware_unlocked()
    idle()

    txb = TxBuffer.process_next_message(state.tx_buffer, state.uart_pid)
    %{state | tx_buffer: txb}
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

  defp reduce({:end_stops_report, %{z_endstop_a: _, z_endstop_b: _}}, s), do: s

  defp reduce({:calibration_state_report, result}, state) do
    result
    |> map_args(fn
      {:x, value} ->
        {:movement_axis_nr_steps_x, value}

      {:y, value} ->
        {:movement_axis_nr_steps_y, value}

      {:z, value} ->
        {:movement_axis_nr_steps_z, value}

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(fn {_, value} -> value < 100 end)
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
    clean_echo = String.replace(echo_string, ["\r", "*"], "")
    next_txb = TxBuffer.process_echo(state.tx_buffer, clean_echo)

    if echo_string == "*F09*" do
      # INBOUND SIDE EFFECT: The Firmware echoed back our
      # unlock command. We can purge the old buffer.
      BotState.set_firmware_unlocked()
      %{state | tx_buffer: TxBuffer.new()}
    else
      %{state | tx_buffer: next_txb}
    end
  end

  defp reduce({:running, _}, state) do
    busy()
    state
  end

  defp reduce({:error, %{queue: q_float} = code}, state) do
    idle()
    err_info = {trunc(q_float), trunc(Map.get(code, :value1) || 0.0)}

    next_txb =
      state.tx_buffer
      |> TxBuffer.process_error(err_info)
      |> TxBuffer.process_next_message(state.uart_pid)

    %{state | tx_buffer: next_txb}
  end

  defp reduce({:invalidation, _}, _), do: raise("FBOS SENT INVALID GCODE")

  defp reduce({:ok, %{queue: q_float}}, state) do
    next_txb =
      state.tx_buffer
      |> TxBuffer.process_ok(trunc(q_float))
      |> TxBuffer.process_next_message(state.uart_pid)

    %{state | tx_buffer: next_txb}
  end

  defp reduce({:not_configured, _}, state) do
    busy()
    state
  end

  defp reduce({:emergency_lock, _}, state) do
    :ok = BotState.set_firmware_locked()
    state
  end

  defp reduce({:param_value_report, %{pin_or_param: p_float, value1: v}}, s) do
    FarmbotOS.Firmware.ConfigUploader.verify_param(s, {trunc(p_float), v})
  end

  defp reduce({:software_version, version}, state) do
    :ok = BotState.set_firmware_version(version)
    state
  end

  defp reduce({:pin_value_report, %{pin_or_param: p, value1: v}}, state) do
    # We don't know the pin's mode, nor does the firmware
    # provide it. We must set the mode to `nil`.
    BotState.set_pin_value(trunc(p), v, nil)
    state
  end

  defp reduce({:different_x_coordinate_than_given, %{x: v}}, s),
    do: maxed(s, :x, v)

  defp reduce({:different_y_coordinate_than_given, %{y: v}}, s),
    do: maxed(s, :y, v)

  defp reduce({:different_z_coordinate_than_given, %{z: v}}, s),
    do: maxed(s, :z, v)

  defp reduce(
         {:report_updated_param_during_calibration,
          %{pin_or_param: p, value1: v}},
         state
       ) do
    k = FarmbotOS.Firmware.Parameter.translate(trunc(p))

    %{k => v}
    |> Asset.update_firmware_config!()
    |> Asset.Private.mark_dirty!(%{})

    state
  end

  defp reduce({:movement_retry, _}, state) do
    FarmbotOS.Logger.debug(1, "Retrying movement")
    state
  end

  defp reduce({:motor_load_report, %{x: x, y: y, z: z}}, state) do
    :ok = BotState.set_load(x, y, z)
    state
  end

  defp reduce({:x_axis_timeout, _}, s), do: s
  defp reduce({:y_axis_timeout, _}, s), do: s
  defp reduce({:z_axis_timeout, _}, s), do: s

  defp reduce(
         {:report_pin_monitor_analog_value, %{pin_or_param: p, value1: v}},
         s
       ) do
    watcher = s.pin_watcher

    if watcher && Process.alive?(watcher) do
      send(watcher, {:pin_data, p, v})
      s
    else
      # Turn off pin watching if the watcher dies.
      off = GCode.new(:F22, P: 199, V: 0)
      next_tx_buffer = TxBuffer.push(s.tx_buffer, nil, off)
      %{s | pin_watcher: nil, tx_buffer: next_tx_buffer}
    end
  end

  defp reduce({:abort, _}, state) do
    FarmbotOS.Logger.info(3, "Movement cancelled")
    state
  end

  defp reduce(unknown, state) do
    msg = "=== Unhandled inbound side effects: #{inspect(unknown)}"
    FarmbotOS.Logger.info(3, msg)
    state
  end

  defp maxed(state, axis, value) do
    axis = String.capitalize("#{axis}")
    disclaimer = "instead of specified destination."

    place =
      if value < 1 do
        "home"
      else
        "max"
      end

    msg = "Stopping at #{axis} #{place} " <> disclaimer
    FarmbotOS.Logger.info(3, msg)
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
