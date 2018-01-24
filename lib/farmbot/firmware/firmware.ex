defmodule Farmbot.Firmware do
  @moduledoc "Allows communication with the firmware."

  use GenStage
  use Farmbot.Logger
  alias Farmbot.Firmware.{Vec3, EstopTimer}

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

  @doc "Set a pin mode (:input | :output)"
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

  @doc "Start the firmware services."
  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  ## GenStage

  defmodule Current do
    @moduledoc false
    defstruct [
      fun: nil,
      args: nil,
      from: nil
    ]
  end

  defmodule State do
    @moduledoc false
    defstruct handler: nil, handler_mod: nil,
      idle: false,
      timer: nil,
      pins: %{},
      params: %{},
      initialized: false,
      initializing: false,
      current: nil,
      timeout_ms: 150_000,
      queue: :queue.new()
  end

  def init([]) do
    handler_mod =
      Application.get_env(:farmbot, :behaviour)[:firmware_handler] || raise("No fw handler.")

    case handler_mod.start_link() do
      {:ok, handler} ->
        Process.flag(:trap_exit, true)
        {
          :producer_consumer,
          %State{handler: handler, handler_mod: handler_mod},
          subscribe_to: [handler], dispatcher: GenStage.BroadcastDispatcher
        }
      {:error, reason} ->
        old = Application.get_all_env(:farmbot)[:behaviour]
        new = Keyword.put(old, :firmware_handler, Farmbot.Firmware.StubHandler)
        Application.put_env(:farmbot, :behaviour, new)
        {:stop, {:handler_init, reason}}
    end

  end

  def terminate(reason, state) do
    unless reason in [:normal, :shutdown] do
      old = Application.get_all_env(:farmbot)[:behaviour]
      new = Keyword.put(old, :firmware_handler, Farmbot.Firmware.StubHandler)
      Application.put_env(:farmbot, :behaviour, new)
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

  def handle_info(:timeout, state) do
    case state.current do
      nil -> {:noreply, [], %{state | timer: nil}}
      %Current{fun: fun, args: args, from: _from} = current ->
        Logger.warn 1, "Timed out waiting for Firmware response. Retrying #{fun}(#{inspect args}) "
        case apply(state.handler_mod, fun, [state.handler | args]) do
          :ok ->
            timer = Process.send_after(self(), :timeout, state.timeout_ms)
            {:noreply, [], %{state | current: current, timer: timer}}
          {:error, _} = res ->
            do_reply(state, res)
            {:noreply, [], %{state | current: nil, queue: :queue.new()}}
        end
        {:noreply, [], %{state | timer: nil}}
    end
  end

  def handle_call({fun, _}, _from, state = %{initialized: false})
  when fun not in  [:read_all_params, :update_param, :emergency_unlock, :emergency_lock] do
    {:reply, {:error, :uninitialized}, [], state}
  end

  def handle_call({fun, args}, from, state) do
    next_current = struct(Current, from: from, fun: fun, args: args)
    current_current = state.current
    cond do
      fun == :emergency_lock ->
        if current_current do
          do_reply(state, {:error, :emergency_lock})
        end
        do_begin_cmd(next_current, state, [])
      match?(%Current{}, current_current) ->
        do_queue_cmd(next_current, state)
      is_nil(current_current) ->
        do_begin_cmd(next_current, state, [])
    end
  end

  defp do_begin_cmd(%Current{fun: fun, args: args, from: _from} = current, state, dispatch) do
    # Logger.busy 3, "FW Starting: #{fun}: #{inspect from}"
    case apply(state.handler_mod, fun, [state.handler | args]) do
      :ok ->
        if fun == :emergency_unlock, do: Farmbot.System.GPIO.Leds.led_status_ok()
        timer = Process.send_after(self(), :timeout, state.timeout_ms)
        {:noreply, dispatch, %{state | current: current, timer: timer}}
      {:error, _} = res ->
        do_reply(%{state | current: current}, res)
        {:noreply, dispatch, %{state | current: nil}}
    end
  end

  defp do_queue_cmd(%Current{fun: _fun, args: _args, from: _from} = current, state) do
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
    if Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "arduino_debug_messages") do
      Logger.debug 3, "Arduino debug message: #{message}"
    end
    {nil, state}
  end

  defp handle_gcode(code, state) when code in [:error, :invalid_command] do
    Logger.warn 1, "Got error gcode (#{code})!"
    maybe_cancel_timer(state.timer)
    if state.current do
      formatted_args = Enum.map(state.current.args, fn(arg) ->
        cond do
          is_atom(arg) -> to_string(arg)
          is_binary(arg) -> to_string(arg)
          true -> inspect(arg)
        end
      end)
      Logger.error 1, "Failed to execute #{state.current.fun} #{inspect formatted_args}"
      do_reply(state, {:error, :firmware_error})
      {nil, %{state | current: nil}}
    else
      {nil, state}
    end
  end

  defp handle_gcode({:report_current_position, x, y, z}, state) do
    {:location_data, %{position: %{x: round(x), y: round(y), z: round(z)}}, state}
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
    mode = if(mode_atom == :digital, do: 0, else: 1)
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
    Farmbot.System.ConfigStorage.update_config_value(:float, "hardware_params", to_string(param), nil)
    {:mcu_params, %{param => nil}, %{state | params: Map.put(state.params, param, value)}}
  end

  defp handle_gcode({:report_parameter_value, param, value}, state) when is_number(value) do
    Farmbot.System.ConfigStorage.update_config_value(:float, "hardware_params", to_string(param), value / 1)
    {:mcu_params, %{param => value}, %{state | params: Map.put(state.params, param, value)}}
  end

  defp handle_gcode(:idle, %{initialized: false, initializing: false} = state) do
    Logger.busy 1, "Initializing Firmware."
    old = Farmbot.System.ConfigStorage.get_config_as_map()["hardware_params"]
    case old["param_version"] do
      nil ->
        Logger.debug 3, "Setting up fresh params."
        spawn __MODULE__, :do_read_params_and_report_position, [%{}]
      _   ->
        Logger.debug 3, "Setting up old params."
        spawn __MODULE__, :do_read_params_and_report_position, [Map.delete(old, "param_version")]
    end
    {nil, %{state | initializing: true}}
  end

  defp handle_gcode(:idle, %{initialized: false, initializing: true} = state) do
    {nil, state}
  end

  defp handle_gcode(:idle, state) do
    maybe_cancel_timer(state.timer)
    Farmbot.BotState.set_busy(false)
    if state.current do
      # This might be a bug in the FW
      if state.current.fun in [:home, :home_all] do
        Logger.warn 1, "Got idle during home. Ignoring. This might be bad."
        timer = Process.send_after(self(), :timeout, state.timeout_ms)
        {nil, %{state | timer: timer}}
      else
        Logger.warn 1, "Got idle while executing a command."
        do_reply(state, {:error, :timeout})
        {:informational_settings, %{busy: false, locked: false}, %{state | current: nil, idle: true}}
      end
    else
      {:informational_settings, %{busy: false, locked: false}, %{state | idle: true}}
    end
  end

  defp handle_gcode(:report_params_complete, state) do
    Logger.success 1, "Firmware initialized."
    {nil, %{state | initializing: false, initialized: true}}
  end

  defp handle_gcode({:report_software_version, version}, state) do
    case String.last(version) do
      "F" ->
        Farmbot.System.ConfigStorage.update_config_value(:string, "settings", "firmware_hardware", "farmduino")
      "R" ->
        Farmbot.System.ConfigStorage.update_config_value(:string, "settings", "firmware_hardware", "arduino")
      _ -> :ok
    end
    {:informational_settings, %{firmware_version: version}, state}
  end

  defp handle_gcode(:report_axis_home_complete_x, state) do
    Logger.success 2, "X Axis homing complete."
    {nil, state}
  end

  defp handle_gcode(:report_axis_home_complete_y, state) do
    Logger.success 2, "Y Axis homing complete."
    {nil, state}
  end

  defp handle_gcode(:report_axis_home_complete_z, state) do
    Logger.success 2, "Z Axis homing complete."
    {nil, state}
  end

  defp handle_gcode(:busy, state) do
    Farmbot.BotState.set_busy(true)
    if state.timer do
      Process.cancel_timer(state.timer)
    end
    timer = Process.send_after(self(), :timeout, state.timeout_ms)
    {:informational_settings, %{busy: true}, %{state | idle: false, timer: timer}}
  end

  defp handle_gcode(:done, state) do
    maybe_cancel_timer(state.timer)
    Farmbot.BotState.set_busy(false)
    if state.current do
      do_reply(state, :ok)
      {nil, %{state | current: nil}}
    else
      {nil, state}
    end
  end

  defp handle_gcode(:report_emergency_lock, state) do
    Farmbot.System.GPIO.Leds.led_status_err
    maybe_send_email()
    if state.current do
      do_reply(state, {:error, :emergency_lock})
      {:informational_settings, %{locked: true}, %{state | current: nil}}
    else
      {:informational_settings, %{locked: true}, state}
    end
  end

  defp handle_gcode({:report_calibration, axis, status}, state) do
    maybe_cancel_timer(state.timer)
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

  defp maybe_cancel_timer(nil), do: :ok
  defp maybe_cancel_timer(timer) do
    if Process.read_timer(timer) do
      Process.cancel_timer(timer)
    end
  end

  @doc false
  def do_read_params_and_report_position(old) when is_map(old) do
    for {key, float_val} <- old do
      cond do
        (float_val == -1) -> :ok
        is_nil(float_val) -> :ok
        is_number(float_val) ->
          val = round(float_val)
          update_param(:"#{key}", val)
      end
    end
    read_all_params()
    request_software_version()
  end

  @doc false
  def report_calibration_callback(tries, param, value)

  def report_calibration_callback(0, _param, _value) do
    :ok
  end

  def report_calibration_callback(tries, param, val) do
    case Farmbot.Firmware.update_param(param, val) do
      :ok ->
        case Farmbot.System.ConfigStorage.get_config_value(:float, "hardware_params", to_string(param)) do
          ^val ->
            Logger.success 1, "Calibrated #{param}: #{val}"
            :ok
          _ -> report_calibration_callback(tries - 1, param, val)
        end
      {:error, reason} ->
        Logger.error 1, "Failed to set #{param}: #{val} (#{inspect reason})"
        report_calibration_callback(tries - 1, param, val)
    end
  end

  defp do_reply(state, reply) do
    maybe_cancel_timer(state.timer)
    case state.current do
      %Current{fun: :emergency_unlock, from: from} ->
        # i really don't want this to be here..
        EstopTimer.cancel_timer()
        :ok = GenServer.reply from, reply
      %Current{fun: :emergency_lock, from: from} ->
        :ok = GenServer.reply from, {:error, :emergency_lock}
      %Current{fun: _fun, from: from} ->
        # Logger.success 3, "FW Replying: #{fun}: #{inspect from}"
        :ok = GenServer.reply from, reply
      nil ->
        Logger.error 1, "FW Nothing to send reply: #{inspect reply} to!."
        :error
    end
  end

  defp maybe_send_email do
    import Farmbot.System.ConfigStorage, only: [get_config_value: 3]
    if get_config_value(:bool, "settings", "email_on_estop") do
      if !EstopTimer.timer_active? do
        EstopTimer.start_timer()
      end
    end
  end
end
