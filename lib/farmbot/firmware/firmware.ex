defmodule Farmbot.Firmware do
  @moduledoc "Allows communication with the firmware."

  use GenStage
  use Farmbot.Logger
  alias Farmbot.Bootstrap.SettingsSync
  alias Farmbot.Firmware.{Command, CompletionLogs, Vec3, EstopTimer, Utils}
  import Utils

  import Farmbot.System.ConfigStorage,
    only: [get_config_value: 3, update_config_value: 4, get_config_as_map: 0]

  import CompletionLogs,
    only: [maybe_log_complete: 2]

  # If any command takes longer than this, exit.
  @call_timeout 500_000

  @doc "Move the bot to a position."
  def move_absolute(%Vec3{} = vec3, x_spd, y_spd, z_spd) do
    call = {:move_absolute, [vec3, x_spd, y_spd, z_spd]}
    GenStage.call(__MODULE__, call, @call_timeout)
  end

  @doc "Calibrate an axis."
  def calibrate(axis) do
    GenStage.call(__MODULE__, {:calibrate, [axis]}, @call_timeout)
  end

  @doc "Find home on an axis."
  def find_home(axis) do
    GenStage.call(__MODULE__, {:find_home, [axis]}, @call_timeout)
  end

  @doc "Home every axis."
  def home_all() do
    GenStage.call(__MODULE__, {:home_all, []}, @call_timeout)
  end

  @doc "Home an axis."
  def home(axis) do
    GenStage.call(__MODULE__, {:home, [axis]}, @call_timeout)
  end

  @doc "Manually set an axis's current position to zero."
  def zero(axis) do
    GenStage.call(__MODULE__, {:zero, [axis]}, @call_timeout)
  end

  @doc """
  Update a paramater.
  For a list of paramaters see `Farmbot.Firmware.Gcode.Param`
  """
  def update_param(param, val) do
    GenStage.call(__MODULE__, {:update_param, [param, val]}, @call_timeout)
  end

  @doc false
  def read_all_params do
    GenStage.call(__MODULE__, {:read_all_params, []}, @call_timeout)
  end

  @doc """
  Read a paramater.
  For a list of paramaters see `Farmbot.Firmware.Gcode.Param`
  """
  def read_param(param) do
    GenStage.call(__MODULE__, {:read_param, [param]}, @call_timeout)
  end

  @doc "Emergency lock Farmbot."
  def emergency_lock() do
    GenStage.call(__MODULE__, {:emergency_lock, []}, @call_timeout)
  end

  @doc "Unlock Farmbot from Emergency state."
  def emergency_unlock() do
    GenStage.call(__MODULE__, {:emergency_unlock, []}, @call_timeout)
  end

  @doc "Set a pin mode (`:input` | `:output` | `:input_pullup`)"
  def set_pin_mode(pin, mode) do
    GenStage.call(__MODULE__, {:set_pin_mode, [pin, mode]}, @call_timeout)
  end

  @doc "Read a pin."
  def read_pin(pin, mode) do
    GenStage.call(__MODULE__, {:read_pin, [pin, mode]}, @call_timeout)
  end

  @doc "Write a pin."
  def write_pin(pin, mode, value) do
    GenStage.call(__MODULE__, {:write_pin, [pin, mode, value]}, @call_timeout)
  end

  @doc "Request version."
  def request_software_version do
    GenStage.call(__MODULE__, {:request_software_version, []}, @call_timeout)
  end

  @doc "Set angle of a servo pin."
  def set_servo_angle(pin, value) do
    GenStage.call(__MODULE__, {:set_servo_angle, [pin, value]}, @call_timeout)
  end

  @doc "Flag for all params reported."
  def params_reported do
    GenStage.call(__MODULE__, :params_reported)
  end

  @doc "Start the firmware services."
  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  ## GenStage

  defmodule State do
    @moduledoc false
    defstruct [
      handler: nil,
      handler_mod: nil,
      idle: false,
      timer: nil,
      pins: %{},
      params: %{},
      params_reported: false,
      initialized: false,
      initializing: false,
      current: nil,
      timeout_ms: 150_000,
      queue: :queue.new(),
      x_needs_home_on_boot: false,
      y_needs_home_on_boot: false,
      z_needs_home_on_boot: false
    ]
  end

  defp needs_home_on_boot do
    x = (get_config_value(:float, "hardware_params", "movement_home_at_boot_x") || 0)
    |> num_to_bool()

    y = (get_config_value(:float, "hardware_params", "movement_home_at_boot_y") || 0)
    |> num_to_bool()

    z = (get_config_value(:float, "hardware_params", "movement_home_at_boot_z") || 0)
    |> num_to_bool()

    %{
      x_needs_home_on_boot: x,
      y_needs_home_on_boot: y,
      z_needs_home_on_boot: z,
    }
  end

  def init([]) do
    handler_mod =
      Application.get_env(:farmbot, :behaviour)[:firmware_handler] || raise("No fw handler.")

    case handler_mod.start_link() do
      {:ok, handler} ->
        initial = Map.merge(needs_home_on_boot(), %{handler: handler, handler_mod: handler_mod})
        Process.flag(:trap_exit, true)
        {
          :producer_consumer,
          struct(State, initial),
          subscribe_to: [handler], dispatcher: GenStage.BroadcastDispatcher
        }
      {:error, reason} ->
        replace_firmware_handler(Farmbot.Firmware.StubHandler)
        Logger.error 1, "Failed to initialize firmware: #{inspect reason} Falling back to stub implementation."
        init([])
    end

  end

  def terminate(reason, state) do
    unless reason in [:normal, :shutdown] do
      replace_firmware_handler(Farmbot.Firmware.StubHandler)
    end

    unless :queue.is_empty(state.queue) do
      list = :queue.to_list(state.queue)
      for cmd <- list do
        :ok = do_reply(%{state | current: cmd}, {:error, reason})
      end
    end
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _, reason}, state) do
    Logger.error 1, "Firmware handler: #{state.handler_mod} died: #{inspect reason}"
    case state.handler_mod.start_link() do
      {:ok, handler} ->
        new_state = %{state | handler: handler}
        {:noreply, [{:informational_settings, %{busy: false}}], %{new_state | initialized: false, idle: false}}
      err -> {:stop, err, %{state | handler: false}}
    end
  end

  # TODO(Connor): Put some sort of exit strategy here.
  # If a firmware command keeps timingout/failing, Farmbot OS just keeps trying
  # it. This can lead to infinate failures.
  def handle_info({:command_timeout, %Command{} = timeout_command}, state) do
    case state.current do
      # Check if this timeout is actually talking about the current command.
      ^timeout_command = current ->
        Logger.warn 1, "Timed out waiting for Firmware response. Retrying #{inspect current}) "
        case apply(state.handler_mod, current.fun, [state.handler | current.args]) do
          :ok ->
            timer = start_timer(current, state.timeout_ms)
            {:noreply, [], %{state | current: current, timer: timer}}
          {:error, _} = res ->
            do_reply(state, res)
            {:noreply, [], %{state | current: nil, queue: :queue.new()}}
        end

      # If this timeout was not talking about the current command
      %Command{} = current ->
        Logger.debug 3, "Got stray timeout for command: #{inspect current}"
        {:noreply, [], %{state | timer: nil}}

      # If there is no current command, we got a different kind of stray.
      # This is ok i guess.
      nil -> {:noreply, [], %{state | timer: nil}}

    end
  end

  def handle_call(:params_reported, _, state) do
    {:reply, state.params_reported, [], state}
  end

  def handle_call({fun, _}, _from, state = %{initialized: false})
  when fun not in  [:read_all_params, :update_param, :emergency_unlock, :emergency_lock, :request_software_version] do
    {:reply, {:error, :uninitialized}, [], state}
  end

  def handle_call({fun, args}, from, state) do
    next_current = struct(Command, from: from, fun: fun, args: args)
    current_current = state.current
    cond do
      fun == :emergency_lock ->
        if current_current do
          do_reply(state, {:error, :emergency_lock})
        end
        do_begin_cmd(next_current, state, [])
      match?(%Command{}, current_current) ->
        do_queue_cmd(next_current, state)
      is_nil(current_current) ->
        do_begin_cmd(next_current, state, [])
    end
  end

  defp do_begin_cmd(%Command{fun: fun, args: args, from: _from} = current, state, dispatch) do
    case apply(state.handler_mod, fun, [state.handler | args]) do
      :ok ->
        timer = start_timer(current, state.timeout_ms)
        if fun == :emergency_unlock do
          new_dispatch = [{:informational_settings,  %{busy: false, locked: false}} | dispatch]
          {:noreply, new_dispatch, %{state | current: current, timer: timer}}
        else
          {:noreply, dispatch, %{state | current: current, timer: timer}}
        end
      {:error, _} = res ->
        do_reply(%{state | current: current}, res)
        {:noreply, dispatch, %{state | current: nil}}
    end
  end

  defp do_queue_cmd(%Command{fun: _fun, args: _args, from: _from} = current, state) do
    # Logger.busy 3, "FW Queuing: #{fun}: #{inspect from}"
    new_q = :queue.in(current, state.queue)
    {:noreply, [], %{state | queue: new_q}}
  end

  def handle_events(gcodes, _from, state) do
    {diffs, state} = handle_gcodes(gcodes, state)
    # if after handling the current buffer of gcodes,
    # Try to start the next command in the queue if it exists.
    if List.last(gcodes) == :idle && state.current == nil do
      case :queue.out(state.queue) do
        {{:value, next_current}, new_queue} ->
          do_begin_cmd(next_current, %{state | queue: new_queue, current: next_current}, diffs)
        {:empty, queue} -> # nothing to do if the queue is empty.
          {:noreply, diffs, %{state | queue: queue}}
      end
    else
      {:noreply, diffs, state}
    end
  end

  defp handle_gcodes(codes, state, acc \\ [])

  defp handle_gcodes([], state, acc), do: {Enum.reverse(acc), state}

  defp handle_gcodes([code | rest], state, acc) do
    case handle_gcode(code, state) do
      {nil, new_state} -> handle_gcodes(rest, new_state, acc)
      {key, diff, new_state} -> handle_gcodes(rest, new_state, [{key, diff} | acc])
    end
  end

  defp handle_gcode({:debug_message, message}, state) do
    if get_config_value(:bool, "settings", "arduino_debug_messages") do
      Logger.debug 3, "Arduino debug message: #{message}"
    end
    {nil, state}
  end

  defp handle_gcode(code, state) when code in [:error, :invalid_command] do
    maybe_cancel_timer(state.timer, state.current)
    if state.current do
      Logger.error 1, "Got #{code} while executing `#{inspect state.current}`."
      do_reply(state, {:error, :firmware_error})
      {nil, %{state | current: nil}}
    else
      {nil, state}
    end
  end

  defp handle_gcode(:report_no_config, state) do
    Logger.busy 1, "Initializing Firmware."
    old = get_config_as_map()["hardware_params"]
    spawn __MODULE__, :do_read_params, [Map.delete(old, "param_version")]
    {nil, %{state | initialized: false, initializing: true}}
  end

  defp handle_gcode(:report_params_complete, state) do
    {nil, %{state | initialized: true, initializing: false}}
  end

  defp handle_gcode(:idle, %{initialized: false, initializing: false} = state) do
    Logger.busy 1, "Firmware not initialized yet. Waiting for R88 message."
    {nil, state}
  end

  defp handle_gcode(:idle, %{initialized: true, initializing: false, current: nil, z_needs_home_on_boot: true} = state) do
    Logger.info 2, "Bootup homing Z axis"
    spawn __MODULE__, :find_home, [:z]
    {nil, %{state | z_needs_home_on_boot: false}}
  end

  defp handle_gcode(:idle, %{initialized: true, initializing: false, current: nil, y_needs_home_on_boot: true} = state) do
    Logger.info 2, "Bootup homing Y axis"
    spawn __MODULE__, :find_home, [:y]
    {nil, %{state | y_needs_home_on_boot: false}}
  end

  defp handle_gcode(:idle, %{initialized: true, initializing: false, current: nil, x_needs_home_on_boot: true} = state) do
    Logger.info 2, "Bootup homing X axis"
    spawn __MODULE__, :find_home, [:x]
    {nil, %{state | x_needs_home_on_boot: false}}
  end

  defp handle_gcode(:idle, state) do
    maybe_cancel_timer(state.timer, state.current)
    Farmbot.BotState.set_busy(false)
    if state.current do
      Logger.warn 1, "Got idle while executing a command."
      timer = start_timer(state.current, state.timeout_ms)
      {nil, %{state | timer: timer}}
    else
      {:informational_settings, %{busy: false, locked: false}, %{state | idle: true}}
    end
  end

  defp handle_gcode({:report_current_position, x, y, z}, state) do
    {:location_data, %{position: %{x: x, y: y, z: z}}, state}
  end

  defp handle_gcode({:report_encoder_position_scaled, x, y, z}, state) do
    {:location_data, %{scaled_encoders: %{x: x, y: y, z: z}}, state}
  end

  defp handle_gcode({:report_encoder_position_raw, x, y, z}, state) do
    {:location_data, %{raw_encoders: %{x: x, y: y, z: z}}, state}
  end

  defp handle_gcode({:report_end_stops, xa, xb, ya, yb, za, zb}, state) do
    diff = %{end_stops: %{xa: xa, xb: xb, ya: ya, yb: yb, za: za, zb: zb}}
    {:location_data, diff, state}
    {nil, state}
  end

  defp handle_gcode({:report_pin_mode, pin, mode_atom}, state) do
    # Logger.debug 3, "Got pin mode report: #{pin}: #{mode_atom}"
    mode = extract_pin_mode(mode_atom)
    case state.pins[pin] do
      %{mode: _, value: _} = pin_map ->
        {:pins, %{pin => %{pin_map | mode: mode}}, %{state | pins: %{state.pins | pin => %{pin_map | mode: mode}}}}
      nil ->
        {:pins, %{pin => %{mode: mode, value: -1}}, %{state | pins: Map.put(state.pins, pin, %{mode: mode, value: -1})}}
    end
  end

  defp handle_gcode({:report_pin_value, pin, value}, state) do
    # Logger.debug 3, "Got pin value report: #{pin}: #{value} old: #{inspect state.pins[pin]}"
    case state.pins[pin] do
      %{mode: _, value: _} = pin_map ->
        {:pins, %{pin => %{pin_map | value: value}}, %{state | pins: %{state.pins | pin => %{pin_map | value: value}}}}
      nil ->
        {:pins, %{pin => %{mode: nil, value: value}}, %{state | pins: Map.put(state.pins, pin, %{mode: nil, value: value})}}
    end
  end

  defp handle_gcode({:report_parameter_value, param, value}, state) when (value == -1) do
    value = maybe_update_param_from_report(to_string(param), nil)
    {:mcu_params, %{param => nil}, %{state | params: Map.put(state.params, param, value)}}
  end

  defp handle_gcode({:report_parameter_value, param, value}, state) when is_number(value) do
    value = maybe_update_param_from_report(to_string(param), value)
    {:mcu_params, %{param => value}, %{state | params: Map.put(state.params, param, value)}}
  end

  defp handle_gcode({:report_software_version, version}, state) do
    case String.last(version) do
      "F" ->
        update_config_value(:string, "settings", "firmware_hardware", "farmduino")
      "R" ->
        update_config_value(:string, "settings", "firmware_hardware", "arduino")
      "G" ->
        update_config_value(:string, "settings", "firmware_hardware", "farmduino_k14")
      _ -> :ok
    end
    {:informational_settings, %{firmware_version: version}, state}
  end

  defp handle_gcode(:report_axis_home_complete_x, state) do
    {nil, state}
  end

  defp handle_gcode(:report_axis_home_complete_y, state) do
    {nil, state}
  end

  defp handle_gcode(:report_axis_home_complete_z, state) do
    {nil, %{state | timer: nil}}
  end

  defp handle_gcode(:report_axis_timeout_x, state) do
    do_reply(state, {:error, :axis_timeout_x})
    {nil, %{state | timer: nil}}
  end

  defp handle_gcode(:report_axis_timeout_y, state) do
    do_reply(state, {:error, :axis_timeout_y})
    {nil, %{state | timer: nil}}
  end

  defp handle_gcode(:report_axis_timeout_z, state) do
    do_reply(state, {:error, :axis_timeout_z})
    {nil, %{state | timer: nil}}
  end

  defp handle_gcode({:report_axis_changed_x, _new_x} = msg, state) do
    new_current = Command.add_status(state.current, msg)
    {nil, %{state | current: new_current}}
  end

  defp handle_gcode({:report_axis_changed_y, _new_y} = msg, state) do
    new_current = Command.add_status(state.current, msg)
    {nil, %{state | current: new_current}}
  end

  defp handle_gcode({:report_axis_changed_z, _new_z} = msg, state) do
    new_current = Command.add_status(state.current, msg)
    {nil, %{state | current: new_current}}
  end

  defp handle_gcode(:busy, state) do
    Farmbot.BotState.set_busy(true)
    maybe_cancel_timer(state.timer, state.current)
    timer = if state.current do
      start_timer(state.current, state.timeout_ms)
    else
      nil
    end
    {:informational_settings, %{busy: true}, %{state | idle: false, timer: timer}}
  end

  defp handle_gcode(:done, state) do
    maybe_cancel_timer(state.timer, state.current)
    Farmbot.BotState.set_busy(false)
    if state.current do
      do_reply(state, :ok)
      {nil, %{state | current: nil}}
    else
      {nil, state}
    end
  end

  defp handle_gcode(:report_emergency_lock, state) do
    maybe_send_email()
    if state.current do
      do_reply(state, {:error, :emergency_lock})
      {:informational_settings, %{locked: true}, %{state | current: nil}}
    else
      {:informational_settings, %{locked: true}, state}
    end
  end

  defp handle_gcode({:report_calibration, axis, status}, state) do
    maybe_cancel_timer(state.timer, state.current)
    Logger.busy 1, "Axis #{axis} calibration: #{status}"
    {nil, state}
  end

  defp handle_gcode({:report_axis_calibration, param, val}, state) do
    spawn __MODULE__, :report_calibration_callback, [5, param, val]
    {nil, state}
  end

  defp handle_gcode(:noop, state) do
    {nil, state}
  end

  defp handle_gcode(:received, state) do
    {nil, state}
  end

  defp handle_gcode({:echo, _code}, state) do
    {nil, state}
  end

  defp handle_gcode(code, state) do
    Logger.warn(3, "unhandled code: #{inspect(code)}")
    {nil, state}
  end

  defp maybe_cancel_timer(nil, current_command) do
    if current_command do
      # Logger.debug 3, "[WEIRD] - No timer to cancel for command: #{inspect current_command}"
      :ok
    else
      # Logger.debug 3, "[PROBABLY OK] - No timer to cancel, and no command here."
      :ok
    end
  end

  defp maybe_cancel_timer(timer, _current_command) do
    if Process.read_timer(timer) do
      # Logger.debug 3, "[NORMAL] - Canceled timer: #{inspect timer} for command: #{inspect current_command}"
      Process.cancel_timer(timer)
      :ok
    else
      :ok
    end
  end

  defp maybe_update_param_from_report(param, val) when is_binary(param) do
    real_val = if val, do: (val / 1), else: nil
    # Logger.debug 3, "Firmware reported #{param} => #{real_val || "nil"}"
    update_config_value(:float, "hardware_params", to_string(param), real_val)
    real_val
  end

  @doc false
  def do_read_params(old) when is_map(old) do
    for {key, float_val} <- old do
      cond do
        (float_val == -1) -> :ok
        is_nil(float_val) -> :ok
        is_number(float_val) ->
          :ok = update_param(:"#{key}", float_val / 1)
      end
    end
    :ok = update_param(:param_use_eeprom, 0)
    :ok = update_param(:param_config_ok, 1)
    read_all_params()
    :ok = request_software_version()
  end

  @doc false
  def report_calibration_callback(tries, param, value)

  def report_calibration_callback(0, _param, _value) do
    :ok
  end

  def report_calibration_callback(tries, param, val) do
    case Farmbot.Firmware.update_param(param, val) do
      :ok ->
        str_param = to_string(param)
        case get_config_value(:float, "hardware_params", str_param) do
          ^val ->
            Logger.success 1, "Calibrated #{param}: #{val}"
            SettingsSync.upload_fw_kv(str_param, val)
            :ok
          _ -> report_calibration_callback(tries - 1, param, val)
        end
      {:error, reason} ->
        Logger.error 1, "Failed to set #{param}: #{val} (#{inspect reason})"
        report_calibration_callback(tries - 1, param, val)
    end
  end

  defp do_reply(state, reply) do
    maybe_cancel_timer(state.timer, state.current)
    maybe_log_complete(state.current, reply)
    case state.current do
      %Command{fun: :emergency_unlock, from: from} ->
        # i really don't want this to be here..
        EstopTimer.cancel_timer()
        :ok = GenServer.reply from, reply
      %Command{fun: :emergency_lock, from: from} ->
        :ok = GenServer.reply from, {:error, :emergency_lock}
      %Command{fun: _fun, from: from} ->
        # Logger.success 3, "FW Replying: #{fun}: #{inspect from}"
        :ok = GenServer.reply from, reply
      nil ->
        Logger.error 1, "FW Nothing to send reply: #{inspect reply} to!."
        :error
    end
  end

  defp maybe_send_email do
    if get_config_value(:bool, "settings", "email_on_estop") do
      if !EstopTimer.timer_active? do
        EstopTimer.start_timer()
      end
    end
  end

  defp start_timer(%Command{} = command, timeout) do
    Process.send_after(self(), {:command_timeout, command}, timeout)
  end
end
