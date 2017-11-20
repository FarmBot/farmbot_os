defmodule Farmbot.Firmware do
  @moduledoc "Allows communication with the firmware."

  use GenStage
  use Farmbot.Logger

  @doc "Move the bot to a position."
  def move_absolute(vec3, speed) do
    GenStage.call(__MODULE__, {:move_absolute, [vec3, speed]}, :infinity)
  end

  @doc "Calibrate an axis."
  def calibrate(axis, speed) do
    GenStage.call(__MODULE__, {:calibrate, [axis, speed]}, :infinity)
  end

  @doc "Find home on an axis."
  def find_home(axis, speed) do
    GenStage.call(__MODULE__, {:find_home, [axis, speed]}, :infinity)
  end

  @doc "Home an axis."
  def home(axis, speed) do
    GenStage.call(__MODULE__, {:home, [axis, speed]}, :infinity)
  end

  @doc "Manually set an axis's current position to zero."
  def zero(axis) do
    GenStage.call(__MODULE__, {:zero, [axis]}, :infinity)
  end

  @doc """
  Update a paramater.
  For a list of paramaters see `Farmbot.Firmware.Gcode.Param`
  """
  def update_param(param, val) do
    GenStage.call(__MODULE__, {:update_param, [param, val]}, :infinity)
  end

  @doc false
  def read_all_params do
    GenStage.call(__MODULE__, {:read_all_params, []}, :infinity)
  end

  @doc """
  Read a paramater.
  For a list of paramaters see `Farmbot.Firmware.Gcode.Param`
  """
  def read_param(param) do
    GenStage.call(__MODULE__, {:read_param, [param]}, :infinity)
  end

  @doc "Emergency lock Farmbot."
  def emergency_lock() do
    GenStage.call(__MODULE__, {:emergency_lock, []}, :infinity)
  end

  @doc "Unlock Farmbot from Emergency state."
  def emergency_unlock() do
    GenStage.call(__MODULE__, {:emergency_unlock, []}, :infinity)
  end

  @doc "Set a pin mode (:input | :output)"
  def set_pin_mode(pin, mode) do
    GenStage.call(__MODULE__, {:set_pin_mode, [pin, mode]}, :infinity)
  end

  @doc "Read a pin."
  def read_pin(pin, mode) do
    GenStage.call(__MODULE__, {:read_pin, [pin, mode]}, :infinity)
  end

  @doc "Write a pin."
  def write_pin(pin, mode, value) do
    GenStage.call(__MODULE__, {:write_pin, [pin, mode, value]}, :infinity)
  end

  @doc "Request version."
  def request_software_version do
    GenStage.call(__MODULE__, {:request_software_version, []}, :infinity)
  end

  @doc "Start the firmware services."
  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  ## GenStage

  defmodule Current do
    defstruct [
      fun: nil,
      args: nil,
      from: nil,

    ]
  end

  defmodule State do
    defstruct handler: nil, handler_mod: nil,
      idle: false,
      timer: nil,
      pins: %{},
      initialized: false,
      initializing: false,
      current: nil,
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
      {:stop, err, state} -> {:stop, err, state}
    end

  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _, reason}, state) do
    Logger.error 1, "Firmware handler: #{state.handler_mod} died: #{inspect reason}"
    {:ok, handler} = state.handler_mod.start_link()
    new_state = %{state | handler: handler}
    {:noreply, [{:informational_settings, %{busy: false}}], %{new_state | initialized: false, idle: false}}
  end

  def handle_info(:timeout, state) do
    case state.current do
      nil -> {:noreply, [], %{state | timer: nil}}
      %Current{fun: fun, args: args, from: from} = current ->
        Logger.warn 1, "Got Firmware timeout. Retrying #{fun}(#{inspect args}) "
        case apply(state.handler_mod, fun, [state.handler | args]) do
          :ok ->
            timer = Process.send_after(self(), :timeout, 6500)
            {:noreply, [], %{state | current: current, timer: timer}}
          {:error, _} = res ->
            GenStage.reply(from, res)
            {:noreply, [], %{state | current: nil, queue: :queue.new()}}
        end
        {:noreply, [], %{state | timer: nil}}
    end

  end

  def handle_call({fun, _}, _from, state = %{initialized: false}) when fun not in  [:read_all_params, :update_param, :emergency_unlock, :emergency_lock] do
    {:reply, {:error, :uninitialized}, [], state}
  end

  def handle_call({fun, args}, from, state) do
    current = struct(Current, from: from, fun: fun, args: args)
    if :queue.is_empty(state.queue) do
      do_begin_cmd(current, state, [])
    else
      do_queue_cmd(current, state)
    end
  end

  defp do_begin_cmd(%Current{fun: fun, args: args, from: _from} = current, state, dispatch) do
    # Logger.debug 3, "Firmware command: #{fun}#{inspect(args)}"
    if fun == :emergency_unlock, do: Farmbot.BotState.set_sync_status(:sync_now)

    case apply(state.handler_mod, fun, [state.handler | args]) do
      :ok ->
        timer = Process.send_after(self(), :timeout, 6500)
        {:noreply, dispatch, %{state | current: current, timer: timer}}
      {:error, _} = res ->
        {:reply, res, dispatch, %{state | current: nil, queue: :queue.new()}}
    end
  end

  defp do_queue_cmd(%Current{fun: _fun, args: _args, from: _from} = current, state) do
    new_q = :queue.in(current, state.queue)
    {:noreply, [], %{state | queue: new_q}}
  end

  def handle_events(gcodes, _from, state) do
    {diffs, state} = handle_gcodes(gcodes, state)
    if state.current == nil do
      case :queue.out(state.queue) do
        {{:value, current}, new_queue} ->
          do_begin_cmd(current, %{state | queue: new_queue, current: current}, diffs)
        {:empty, queue} ->
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
    Logger.debug 3, "Arduino debug message: #{message}"
    {nil, state}
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

  defp handle_gcode({:report_parameter_value, param, value}, state) do
    Farmbot.System.ConfigStorage.update_config_value(:float, "hardware_params", to_string(param), value / 1)
    {:mcu_params, %{param => value}, state}
  end

  defp handle_gcode(:idle, %{initialized: false, initializing: false} = state) do
    Logger.busy 3, "Initializing Firmware."
    old = Farmbot.System.ConfigStorage.get_config_as_map()["hardware_params"]
    case old["param_version"] do
      nil -> spawn __MODULE__, :read_all_params, []
      _ -> spawn fn() ->
        for {key, float_val} <- old do
          if float_val do
            val = round(float_val)
            update_param(:"#{key}", val)
          end
        end
        read_all_params()
        request_software_version()
      end
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
      GenServer.reply(state.current.from, {:error, :timeout})
      {:informational_settings, %{busy: false}, %{state | current: nil, idle: true}}
    else
      {:informational_settings, %{busy: false}, %{state | idle: true}}
    end
  end

  defp handle_gcode(:report_params_complete, state) do
    Logger.success 3, "Firmware initialized."
    {nil, %{state | initialized: true}}
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
    Logger.success 3, "X Axis homing complete."
    {nil, state}
  end

  defp handle_gcode(:report_axis_home_complete_y, state) do
    Logger.success 3, "Y Axis homing complete."
    {nil, state}
  end

  defp handle_gcode(:report_axis_home_complete_z, state) do
    Logger.success 3, "Z Axis homing complete."
    {nil, state}
  end

  defp handle_gcode(:busy, state) do
    Farmbot.BotState.set_busy(true)
    if state.timer do
      Process.cancel_timer(state.timer)
    end
    timer = Process.send_after(self(), :timeout, 6500)
    {:informational_settings, %{busy: true}, %{state | idle: false, timer: timer}}
  end

  defp handle_gcode(:done, state) do
    maybe_cancel_timer(state.timer)
    if state.current do
      GenStage.reply(state.current.from, :ok)
      {nil, %{state | current: nil}}
    else
      {nil, state}
    end
  end

  defp handle_gcode(:report_emergency_lock, state) do
    if state.current do
      GenStage.reply(state.current.from, {:error, :emergency_lock})
      {:informational_settings, %{sync_status: :locked}, %{state | current: nil}}
    else
      {:informational_settings, %{sync_status: :locked}, state}
    end
  end

  defp handle_gcode(:error, state) do
    maybe_cancel_timer(state.timer)
    if state.current do
      Logger.error 1, "Failed to execute #{state.current.fun}#{inspect state.current.args}"
      GenStage.reply(state.current.from, {:error, :firmware_error})
      {nil, %{state | current: nil}}
    else
      {nil, state}
    end
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
end
