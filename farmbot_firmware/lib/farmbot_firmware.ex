defmodule Farmbot.Firmware do
  @moduledoc """
  Firmware wrapper for interacting with Farmbot-Arduino-Firmware.
  This GenServer is expected to be a pretty simple state machine
  with no side effects to anything in the rest of the Farmbot application.
  Side effects should be implemented using a callback/pubsub system. This
  allows for indpendent testing.

  Functionality that is needed to boot the firmware:
    * paramaters - Keyword list of {param_atom, float}

  Side affects that should be handled
    * position reports
    * end stop reports
    * calibration reports
    * busy reports

  # State machine
  The firmware starts in a `:boot` state. It then loads all paramaters
  writes all paramaters, and goes to idle if all params were loaded successfully.

  State machine flows go as follows:
  ## Boot
      :boot
      |> :no_config
      |> :configuration
      |> :idle

  ## Idle
      :idle
      |> :begin
      |> :busy
      |> :error | :invalid | :success

  # Constraints and Exceptions
  Commands will be queued as they received with some exceptions:
  * if a command is currently executing (state is not `:idle`),
    proceding commands will be queued in the order they are received.
  * the `:emergency_lock` and `:emergency_unlock` commands go to the front
    of the command queue and are started immediately.
  * if a `report_emergency_lock` message is received at any point during a
    commands execution, that command is considered an error.
    (this does not apply to `:boot` state, since `:write_paramater`
     is accepted while the firmware is locked.)
  * all reports outside of control flow reports (:begin, :error, :invalid,
    :success) will be discarded while in `:boot` state. This means while
    booting, position updates, end stop updates etc are ignored.

  # Transports
  GCODES should be exchanged in the following format:
      {tag, {command, args}}
  * `tag` - binary integer. This is translated to the `Q` paramater.
  * `command` - either a `RXX`, `FXX`, or `GXX` code.
  * `args` - a list of arguments to be processed.

  For example a report might look like:
      {"123", {:report_some_information, [h: 10.00, u: 90.10]}}
  and a command might look like:
      {"555", {:fire_laser, [w: 100.00]}}
  Numbers should be floats when possible. An Exeption to this is `:report_end_stops`
  where there is only two values: `1` or `0`.

  See the `GCODE` module for more information on available implemented GCODES.
  a `Transport` should be a process that implements standard `GenServer`
  behaviour.

  Upon `init/1` the args passed in should be a Keyword list required to configure
  the transport such as a serial device, etc. `args` will also contain a
  `:handle_gcode` function that should be called everytime a GCODE is received.

      Keyword.fetch!(args, :handle_gcode).({"999", {:report_software_version, ["Just a test!"]}})

  a transport should also implement a `handle_call` clause like:

      def handle_call({"166", {:write_paramater, [some_param: 100.00]}}, _from, state)

  and reply with `:ok | {:error, term()}`
  """
  use GenServer
  require Logger

  alias Farmbot.Firmware, as: State
  @error_timeout_ms 2_000

  defstruct [
    :transport,
    :transport_pid,
    :status,
    :tag,
    :configuration_queue,
    :command_queue,
    :caller_pid,
    :current
  ]

  @doc """
  Command the firmware to do something. Takes a `{tag, {command, args}}`
  GCODE. This command will be queued if there is already a command
  executing. (this does not apply to `:emergency_lock` and `:emergency_unlock`)

  ## Response/Control Flow
  When executed, `command` will block until one of the following respones
  are received:
    * `{:report_success, []}` -> `:ok`
    * `{:report_invalid, []}` -> `{:error, :invalid_command}`
    * `{:report_error, []}` -> `{:error, :firmware_error}`
    * `{:report_emergency_lock, []}` -> {:error, :emergency_lock}`

  If the firmware is in any of the following states:
    * `:booting`
    * `:no_config`
    * `:configuration`
  `command` will fail with `{:error, state}`
  """
  def command(firmware_server \\ __MODULE__, code)

  def command(firmware_server, {_tag, {_, _}} = code) do
    case GenServer.call(firmware_server, code, :infinity) do
      {:ok, tag} -> wait_for_result(tag, code)
      {:error, status} -> {:error, status}
    end
  end

  def command(firmware_server, {_, _} = code) do
    command(firmware_server, {to_string(:rand.uniform(100)), code})
  end

  defp wait_for_result(tag, code) do
    receive do
      {^tag, {:report_begin, []}} ->
        wait_for_result(tag, code)

      {^tag, {:report_busy, []}} ->
        wait_for_result(tag, code)

      {^tag, {:report_success, []}} ->
        :ok

      {^tag, {:report_error, []}} ->
        {:error, :firmware_error}

      {^tag, {:report_invalid, []}} ->
        {:error, :invalid_command}

      {_, {:report_emergency_lock, []}} ->
        {:error, :emergency_lock}

      # {^tag, unhandled_code} -> {:error, {:unknown_response, unhandled_code}}
      {tag, _report} = code ->
        IO.inspect(code, label: "wait_for_result")
        wait_for_result(tag, code)
    end
  end

  @doc """
  Starting the Firmware server requires at least:
  * `:transport` - a module implementing the Transport GenServer behaviour.
    See the `Transports` section of moduledoc.

  Every other arg passed in will be passed directly to the `:transport` module's
  `init/1` function.
  """
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    transport = Keyword.fetch!(args, :transport)
    fw = self()
    fun = fn {_, _} = code -> GenServer.cast(fw, code) end
    args = Keyword.put(args, :handle_gcode, fun)

    with {:ok, pid} <- GenServer.start_link(transport, args) do
      Process.link(pid)

      state = %State{
        transport_pid: pid,
        transport: transport,
        status: :booting,
        command_queue: [],
        configuration_queue: []
      }

      {:ok, state}
    end
  end

  def handle_info(:timeout, %{configuration_queue: [code | rest]} = state) do
    Logger.debug("Starting next configuration code: #{inspect(code)}")

    case GenServer.call(state.transport_pid, {state.tag, code}) do
      :ok -> {:noreply, %{state | current: code, configuration_queue: rest}}
      {:error, _} -> {:noreply, state, @error_timeout_ms}
    end
  end

  def handle_info(:timeout, %{command_queue: [{pid, {tag, code}} | rest]} = state) do
    case GenServer.call(state.transport_pid, {tag, code}) do
      :ok -> {:noreply, %{state | tag: tag, current: code, command_queue: rest, caller_pid: pid}}
      {:error, _} -> {:noreply, state, @error_timeout_ms}
    end
  end

  def handle_info(:timeout, %{configuration_queue: []} = state) do
    {:noreply, state}
  end

  def handle_call(_, _, %{status: s} = state) when s in [:booting, :no_config, :configuration] do
    {:reply, {:error, s.status}, state}
  end

  def handle_call({tag, {:emergency_lock, []}} = code, {pid, _ref}, state) do
    {:reply, {:ok, tag}, %{state | command_queue: [{pid, code} | state.command_queue]}, 0}
  end

  def handle_call({tag, {:emergency_unlock, []}} = code, {pid, _ref}, state) do
    {:reply, {:ok, tag}, %{state | command_queue: [{pid, code} | state.command_queue]}, 0}
  end

  def handle_call({tag, {_, _}} = code, {pid, _ref}, state) do
    new_state = %{state | command_queue: state.command_queue ++ [{pid, code}]}

    case new_state.status do
      :idle ->
        {:reply, {:ok, tag}, new_state, 0}

      _ ->
        {:reply, {:ok, tag}, new_state}
    end
  end

  # Extracts tag
  def handle_cast({tag, {_, _} = code}, state) do
    handle_cast(code, %{state | tag: tag})
  end

  def handle_cast({:report_emergency_lock, []} = code, state) do
    Logger.info("Emergency lock")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, %{state | current: nil, caller_pid: nil}, 0}
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
    {:noreply, goto(%{state | caller_pid: nil, current: nil}, :idle), 0}
  end

  def handle_cast({:report_begin, []} = code, state) do
    Logger.debug("#{inspect(state.current)} begin")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, state}
  end

  def handle_cast({:report_success, []} = code, state) do
    Logger.debug("#{inspect(state.current)} success")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, %{state | current: nil, caller_pid: nil}, 0}
  end

  def handle_cast({:report_busy, []} = code, state) do
    Logger.debug("#{inspect(state.current)} busy")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, state}
  end

  def handle_cast({:report_error, []} = code, %{status: :configuration} = state) do
    Logger.error("#{inspect(state.current)} configuration command error")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:stop, {:error, state.current}, state}
  end

  def handle_cast({:report_error, []} = code, state) do
    Logger.debug("#{inspect(state.current)} error")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, %{state | caller_pid: nil, current: nil}, 0}
  end

  def handle_cast({:report_invalid, []} = code, %{status: :configuration} = state) do
    Logger.debug("#{inspect(state.current)} configuration error (invalid)")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:stop, {:error, state.current}, state}
  end

  def handle_cast({:report_invalid, []} = code, state) do
    Logger.debug("#{inspect(state.current)} error (invalid)")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, %{state | caller_pid: nil, current: nil}, 0}
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

    {:noreply, goto(%{state | tag: tag, configuration_queue: to_process}, :configuring), 0}
  end

  # report_paramaters_complete => goto(:configuring, :idle)
  def handle_cast({:report_paramaters_complete, []}, %{status: :configuring} = state) do
    {:noreply, goto(state, :idle)}
  end

  def handle_cast(_, %{status: :no_config} = state) do
    Logger.debug("Still configuring")
    {:noreply, state}
  end

  def handle_cast({:report_position, _} = _code, state) do
    {:noreply, state}
  end

  def handle_cast({:report_encoders_scaled, _} = _code, state) do
    {:noreply, state}
  end

  def handle_cast({:report_encoders_raw, _} = _code, state) do
    {:noreply, state}
  end

  def handle_cast({:report_end_stops, _} = _code, state) do
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
