defmodule FarmbotFirmware.ReportHandler do
  require Logger

  @doc false
  @spec handle_report({GCODE.report_kind(), GCODE.args()}, state) ::
          {:noreply, state()}
  def handle_report({:report_emergency_lock, []} = code, state) do
    Logger.info("Emergency lock")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    for {pid, _code} <- state.command_queue, do: send(pid, code)

    send(self(), :timeout)
    {:noreply, goto(%{state | current: nil, caller_pid: nil}, :emergency_lock)}
  end

  # "ARDUINO STARTUP COMPLETE" => goto(:boot, :no_config)
  def handle_report(
        {:unknown, [_, "ARDUINO", "STARTUP", "COMPLETE"]},
        %{status: :boot} = state
      ) do
    Logger.info("ARDUINO STARTUP COMPLETE (text) transport=#{state.transport}")
    handle_report({:report_no_config, []}, state)
  end

  def handle_report(
        {:report_idle, []},
        %{status: :boot} = state
      ) do
    Logger.info("ARDUINO STARTUP COMPLETE (idle) transport=#{state.transport}")
    handle_report({:report_no_config, []}, state)
  end

  def handle_report(
        {:report_debug_message, ["ARDUINO STARTUP COMPLETE"]},
        %{status: :boot} = state
      ) do
    Logger.info("ARDUINO STARTUP COMPLETE (r99) transport=#{state.transport}")
    handle_report({:report_no_config, []}, state)
  end

  # report_no_config => goto(_, :no_config)
  def handle_report({:report_no_config, []}, %{status: _} = state) do
    Logger.warn(":report_no_config received")
    tag = state.tag || "0"
    loaded_params = side_effects(state, :load_params, []) || []

    param_commands =
      Enum.reduce(loaded_params, [], fn {param, val}, acc ->
        if val, do: acc ++ [{:parameter_write, [{param, val}]}], else: acc
      end)

    to_process =
      [{:software_version_read, []} | param_commands] ++
        [
          {:parameter_write, [{:param_use_eeprom, 0.0}]},
          {:parameter_write, [{:param_config_ok, 1.0}]},
          {:parameter_read_all, []}
        ]

    to_process =
      if loaded_params[:movement_home_at_boot_z] == 1,
        do: to_process ++ [{:command_movement_find_home, [:z]}],
        else: to_process

    to_process =
      if loaded_params[:movement_home_at_boot_y] == 1,
        do: to_process ++ [{:command_movement_find_home, [:y]}],
        else: to_process

    to_process =
      if loaded_params[:movement_home_at_boot_x] == 1,
        do: to_process ++ [{:command_movement_find_home, [:x]}],
        else: to_process

    send(self(), :timeout)

    {:noreply,
     goto(%{state | tag: tag, configuration_queue: to_process}, :configuration)}
  end

  def handle_report({:report_debug_message, msg}, state) do
    side_effects(state, :handle_debug_message, [msg])
    {:noreply, state}
  end

  def handle_report(report, %{status: :boot} = state) do
    Logger.debug(["still in state: :boot ", inspect(report)])
    {:noreply, state}
  end

  # an idle report while there is a current command running
  # should not count.
  def handle_report({:report_idle, []}, %{current: c} = state)
      when is_tuple(c) do
    if state.caller_pid,
      do: send(state.caller_pid, {state.tag, {:report_busy, []}})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    {:noreply, state}
  end

  # report_idle => goto(_, :idle)
  def handle_report({:report_idle, []}, %{status: _} = state) do
    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_busy, [false])
    side_effects(state, :handle_idle, [true])
    send(self(), :timeout)
    {:noreply, goto(%{state | caller_pid: nil, current: nil}, :idle)}
  end

  def handle_report({:report_begin, []} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    {:noreply, goto(state, :begin)}
  end

  def handle_report({:report_success, []} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    new_state = %{state | current: nil, caller_pid: nil}
    side_effects(state, :handle_busy, [false])
    send(self(), :timeout)
    {:noreply, goto(new_state, :idle)}
  end

  def handle_report({:report_busy, []} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_busy, [true])
    {:noreply, goto(state, :busy)}
  end

  def handle_report(
        {:report_error, _} = code,
        %{status: :configuration} = state
      ) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_busy, [false])
    {:stop, {:error, state.current}, state}
  end

  def handle_report({:report_error, _} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_busy, [false])
    send(self(), :timeout)
    {:noreply, %{state | caller_pid: nil, current: nil}}
  end

  def handle_report(
        {:report_invalid, []} = code,
        %{status: :configuration} = state
      ) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    {:stop, {:error, state.current}, state}
  end

  def handle_report({:report_invalid, []} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    send(self(), :timeout)
    {:noreply, %{state | caller_pid: nil, current: nil}}
  end

  def handle_report(
        {:report_retry, []} = code,
        %{status: :configuration} = state
      ) do
    Logger.warn("Retrying configuration command: #{inspect(code)}")
    {:noreply, state}
  end

  def handle_report({:report_retry, []} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    {:noreply, state}
  end

  def handle_report({:report_parameter_value, param} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_parameter_value, [param])
    {:noreply, state}
  end

  def handle_report({:report_calibration_parameter_value, param} = _code, state) do
    to_process = [{:parameter_write, param}]
    side_effects(state, :handle_parameter_value, [param])
    side_effects(state, :handle_parameter_calibration_value, [param])
    send(self(), :timeout)

    {:noreply,
     goto(
       %{state | tag: state.tag, configuration_queue: to_process},
       :configuration
     )}
  end

  # report_parameters_complete => goto(:configuration, :idle)
  def handle_report(
        {:report_parameters_complete, []},
        %{status: status} = state
      )
      when status in [:begin, :configuration] do
    {:noreply, goto(state, :idle)}
  end

  def handle_report(_, %{status: :no_config} = state) do
    {:noreply, state}
  end

  def handle_report({:report_position, position} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_position, [position])
    {:noreply, state}
  end

  def handle_report({:report_load, load} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_load, [load])
    {:noreply, state}
  end

  def handle_report({:report_axis_state, axis_state} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_axis_state, [axis_state])
    {:noreply, state}
  end

  def handle_report({:report_axis_timeout, [axis]} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_axis_timeout, [axis])
    {:noreply, state}
  end

  def handle_report(
        {:report_calibration_state, calibration_state} = code,
        state
      ) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_calibration_state, [calibration_state])
    {:noreply, state}
  end

  def handle_report({:report_home_complete, axis} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_home_complete, axis)
    {:noreply, state}
  end

  def handle_report({:report_position_change, position} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_position_change, [position])
    {:noreply, state}
  end

  def handle_report({:report_encoders_scaled, encoders} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_encoders_scaled, [encoders])
    {:noreply, state}
  end

  def handle_report({:report_encoders_raw, encoders} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_encoders_raw, [encoders])
    {:noreply, state}
  end

  def handle_report({:report_end_stops, end_stops} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_end_stops, [end_stops])
    {:noreply, state}
  end

  def handle_report({:report_pin_value, value} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_pin_value, [value])
    {:noreply, state}
  end

  def handle_report({:report_software_version, version} = code, state) do
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})

    for {pid, _code} <- state.command_queue,
        do: send(pid, {state.tag, {:report_busy, []}})

    side_effects(state, :handle_software_version, [version])
    {:noreply, state}
  end

  # NOOP
  def handle_report({:report_echo, _}, state), do: {:noreply, state}

  def handle_report({_kind, _args} = code, state) do
    Logger.warn("unknown code for #{state.status}: #{inspect(code)}")
    {:noreply, state}
  end
end
