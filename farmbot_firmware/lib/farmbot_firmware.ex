defmodule Farmbot.Firmware do
  use GenServer
  require Logger

  alias Farmbot.Firmware, as: State
  @error_timeout_ms 2_000

  defstruct [
    :transport,
    :transport_pid,
    :status,
    :tag,
    :queue,
    :current
  ]

  def command(firmware_server \\ __MODULE__, code)

  def command(firmware_server, {_tag, {_, _}} = code) do
    GenServer.call(firmware_server, code)
  end

  def command(firmware_server, {_, _} = code) do
    command(firmware_server, {nil, code})
  end

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    transport = Keyword.fetch!(args, :transport)
    fw = self()
    fun = fn {_, _} = code -> GenServer.cast(fw, code) end
    args = Keyword.put(args, :handle_gcode, fun)

    with {:ok, pid} <- GenServer.start_link(transport, args) do
      {:ok, %State{transport_pid: pid, transport: transport, status: :booting}}
    end
  end

  def handle_info(:timeout, %{queue: [code | rest]} = state) do
    Logger.debug("Starting next code: #{inspect(code)}")

    case GenServer.call(state.transport_pid, {state.tag, code}) do
      :ok -> {:noreply, %{state | current: code, queue: rest}}
      {:error, _} -> {:noreply, state, @error_timeout_ms}
    end
  end

  def handle_info(:timeout, %{queue: []} = state) do
    {:noreply, state}
  end

  # Extracts tag
  def handle_cast({tag, {_, _} = code}, state) do
    handle_cast(code, %{state | tag: tag})
  end

  # "ARDUINO STARTUP COMPLETE" => goto(:booting, :no_config)
  def handle_cast({:report_debug_message, "ARDUINO STARTUP COMPLETE"}, state) do
    {:noreply, goto(state, :no_config)}
  end

  def handle_cast(_, %{status: :booting} = state) do
    Logger.debug("Still booting")
    {:noreply, state}
  end

  # report_idle => goto(_, :idle)
  def handle_cast({:report_idle, []}, state) do
    {:noreply, goto(state, :idle)}
  end

  def handle_cast({:report_begin, []}, state) do
    Logger.debug("#{inspect(state.current)} begin")
    {:noreply, state}
  end

  def handle_cast({:report_success, []}, state) do
    Logger.debug("#{inspect(state.current)} success")
    {:noreply, %{state | current: nil}, 0}
  end

  def handle_cast({:report_busy, []}, state) do
    Logger.debug("#{inspect(state.current)} busy")
    {:noreply, state}
  end

  def handle_cast({:report_error, []}, %{status: :configuration} = state) do
    Logger.debug("#{inspect(state.current)} error")
    {:stop, {:error, state.current}, state}
  end

  def handle_cast({:report_invalid, []}, %{status: :configuration} = state) do
    Logger.debug("#{inspect(state.current)} error (invalid)")
    {:stop, {:error, state.current}, state}
  end

  # report_no_config => goto(_, :no_config)
  def handle_cast({:report_no_config, []}, state) do
    Logger.warn("Configuring paramaters.")
    tag = state.tag || "0"

    param_commands =
      Enum.reduce(load_params(), [], fn {param, val}, acc ->
        if val, do: acc ++ [{:write_paramater, [param, val]}], else: acc
      end)

    to_process =
      param_commands ++
        [
          {:write_paramater, [{:param_config_ok, 1.0}]},
          {:read_all_paramaters, []}
        ]

    {:noreply, goto(%{state | tag: tag, queue: to_process}, :configuring), 0}
  end

  # report_paramaters_complete => goto(:configuring, :idle)
  def handle_cast({:report_paramaters_complete, []}, %{status: :configuring} = state) do
    {:noreply, goto(state, :idle)}
  end

  def handle_cast(_, %{status: :no_config} = state) do
    Logger.debug("Still configuring")
    {:noreply, state}
  end

  def handle_cast({:report_position, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:report_encoders_scaled, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:report_encoders_raw, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:report_end_stops, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:report_paramater, [{param, value}]}, state) do
    {:noreply, state}
  end

  # NOOP
  def handle_cast({:report_echo, _}, state), do: {:noreply, state}

  def handle_cast({_kind, _args} = code, state) do
    IO.inspect(code, label: "unknown code for #{state.status}")
    # {:stop, {:unhandled_code, code}, state}
    {:noreply, state}
  end

  defp goto(%{status: _old} = state, new), do: %{state | status: new}

  # Side effect functions TODO(Connor) refactor these
  def load_params do
    Farmbot.Asset.firmware_config()
    |> Map.take([
      :param_e_stop_on_mov_err,
      :param_mov_nr_retry,
      :movement_timeout_x,
      :movement_timeout_y,
      :movement_timeout_z,
      :movement_keep_active_x,
      :movement_keep_active_y,
      :movement_keep_active_z,
      :movement_home_at_boot_x,
      :movement_home_at_boot_y,
      :movement_home_at_boot_z,
      :movement_invert_endpoints_x,
      :movement_invert_endpoints_y,
      :movement_invert_endpoints_z,
      :movement_enable_endpoints_x,
      :movement_enable_endpoints_y,
      :movement_enable_endpoints_z,
      :movement_invert_motor_x,
      :movement_invert_motor_y,
      :movement_invert_motor_z,
      :movement_secondary_motor_x,
      :movement_secondary_motor_invert_x,
      :movement_steps_acc_dec_x,
      :movement_steps_acc_dec_y,
      :movement_steps_acc_dec_z,
      :movement_stop_at_home_x,
      :movement_stop_at_home_y,
      :movement_stop_at_home_z,
      :movement_home_up_x,
      :movement_home_up_y,
      :movement_home_up_z,
      :movement_step_per_mm_x,
      :movement_step_per_mm_y,
      :movement_step_per_mm_z,
      :movement_min_spd_x,
      :movement_min_spd_y,
      :movement_min_spd_z,
      :movement_home_spd_x,
      :movement_home_spd_y,
      :movement_home_spd_z,
      :movement_max_spd_x,
      :movement_max_spd_y,
      :movement_max_spd_z,
      :encoder_enabled_x,
      :encoder_enabled_y,
      :encoder_enabled_z,
      :encoder_type_x,
      :encoder_type_y,
      :encoder_type_z,
      :encoder_missed_steps_max_x,
      :encoder_missed_steps_max_y,
      :encoder_missed_steps_max_z,
      :encoder_scaling_x,
      :encoder_scaling_y,
      :encoder_scaling_z,
      :encoder_missed_steps_decay_x,
      :encoder_missed_steps_decay_y,
      :encoder_missed_steps_decay_z,
      :encoder_use_for_pos_x,
      :encoder_use_for_pos_y,
      :encoder_use_for_pos_z,
      :encoder_invert_x,
      :encoder_invert_y,
      :encoder_invert_z,
      :movement_axis_nr_steps_x,
      :movement_axis_nr_steps_y,
      :movement_axis_nr_steps_z,
      :movement_stop_at_max_x,
      :movement_stop_at_max_y,
      :movement_stop_at_max_z,
      :pin_guard_1_pin_nr,
      :pin_guard_1_time_out,
      :pin_guard_1_active_state,
      :pin_guard_2_pin_nr,
      :pin_guard_2_time_out,
      :pin_guard_2_active_state,
      :pin_guard_3_pin_nr,
      :pin_guard_3_time_out,
      :pin_guard_3_active_state,
      :pin_guard_4_pin_nr,
      :pin_guard_4_time_out,
      :pin_guard_4_active_state,
      :pin_guard_5_pin_nr,
      :pin_guard_5_time_out,
      :pin_guard_5_active_state
    ])
    |> Map.to_list()
  end
end
