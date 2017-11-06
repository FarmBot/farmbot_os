defmodule Farmbot.Firmware do
  @moduledoc "Allows communication with the firmware."

  use GenStage
  require Logger

  @doc "Move the bot to a position."
  def move_absolute(vec3, speed) do
    GenStage.call(__MODULE__, {:move_absolute, [vec3, speed]})
  end

  @doc "Calibrate an axis."
  def calibrate(axis, speed) do
    GenStage.call(__MODULE__, {:calibrate, [axis, speed]})
  end

  @doc "Find home on an axis."
  def find_home(axis, speed) do
    GenStage.call(__MODULE__, {:find_home, [axis, speed]})
  end

  @doc "Home an axis."
  def home(axis, speed) do
    GenStage.call(__MODULE__, {:home, [axis, speed]})
  end

  @doc "Manually set an axis's current position to zero."
  def zero(axis, speed) do
    GenStage.call(__MODULE__, {:zero, [axis, speed]})
  end

  @doc """
  Update a paramater.
  For a list of paramaters see `Farmbot.Firmware.Gcode.Param`
  """
  def update_param(param, val) do
    GenStage.call(__MODULE__, {:update_param, [param, val]})
  end

  @doc """
  Read a paramater.
  For a list of paramaters see `Farmbot.Firmware.Gcode.Param`
  """
  def read_param(param) do
    GenStage.call(__MODULE__, {:read_param, [param]})
  end

  @doc "Emergency lock Farmbot."
  def emergency_lock() do
    GenStage.call(__MODULE__, {:emergency_lock, []})
  end

  @doc "Unlock Farmbot from Emergency state."
  def emergency_unlock() do
    GenStage.call(__MODULE__, {:emergency_unlock, []})
  end

  @doc "Read a pin."
  def read_pin(pin, mode) do
    GenStage.call(__MODULE__, {:read_pin, [pin, mode]})
  end

  @doc "Write a pin."
  def write_pin(pin, mode, value) do
    GenStage.call(__MODULE__, {:write_pin, [pin, mode, value]})
  end

  @doc "Start the firmware services."
  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  ## GenStage

  defmodule State do
    defstruct handler: nil, handler_mod: nil, idle: false, pins: %{}
  end

  def init([]) do
    handler_mod =
      Application.get_env(:farmbot, :behaviour)[:firmware_handler] || raise("No fw handler.")

    {:ok, handler} = handler_mod.start_link()
    Process.link(handler)

    {
      :producer_consumer,
      %State{handler: handler, handler_mod: handler_mod},
      subscribe_to: [handler], dispatcher: GenStage.BroadcastDispatcher
    }
  end

  def handle_call({fun, args}, _from, %{handler: handler, handler_mod: handler_mod} = state) do
    res =
      case apply(handler_mod, fun, [handler | args]) do
        {:ok, _} = res -> res
        :ok = res -> res
        {:error, _} = res -> res
      end

    {:reply, res, [], state}
  end

  def handle_events(gcodes, _from, state) do
    {diffs, state} = handle_gcodes(gcodes, state)
    {:noreply, diffs, state}
  end

  defp handle_gcodes(codes, state, acc \\ [])

  defp handle_gcodes([], state, acc), do: {Enum.reverse(acc), state}

  defp handle_gcodes([code | rest], state, acc) do
    case handle_gcode(code, state) do
      {nil, new_state} -> handle_gcodes(rest, new_state, acc)
      {key, diff, new_state} -> handle_gcodes(rest, new_state, [{key, diff} | acc])
    end
  end

  defp handle_gcode({:debug_message, _message}, state) do
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
    Logger.debug "Got pin mode report: #{pin}: #{mode_atom}"
    mode = if(mode_atom == :digital, do: 0, else: 1)
    case state.pins[pin] do
      %{mode: _, value: _} = pin_map ->
        {:pins, %{pin => %{pin_map | mode: mode}}, %{state | pins: %{state.pins | pin => %{pin_map | mode: mode}}}}
      nil ->
        {:pins, %{pin => %{mode: mode, value: -1}}, %{state | pins: Map.put(state.pins, pin, %{mode: mode, value: -1})}}
    end
  end

  defp handle_gcode({:report_pin_value, pin, value}, state) do
    Logger.debug "Got pin value report: #{pin}: #{value} old: #{inspect state.pins[pin]}"
    case state.pins[pin] do
      %{mode: _, value: _} = pin_map ->
        {:pins, %{pin => %{pin_map | value: value}}, %{state | pins: %{state.pins | pin => %{pin_map | value: value}}}}
      nil ->
        {:pins, %{pin => %{mode: nil, value: value}}, %{state | pins: Map.put(state.pins, pin, %{mode: nil, value: value})}}
    end
  end

  defp handle_gcode(:idle, state) do
    {:informational_settings, %{busy: false}, %{state | idle: true}}
  end

  defp handle_gcode(code, state) do
    Logger.warn("unhandled code: #{inspect(code)}")
    {nil, state}
  end
end
