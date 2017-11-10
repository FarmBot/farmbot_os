defmodule Farmbot.Firmware.UartHandler do
  @moduledoc """
  Handles communication between farmbot and uart devices
  """

  use GenStage
  alias Nerves.UART
  use Farmbot.Logger
  @behaviour Farmbot.Firmware.Handler

  def start_link do
    GenStage.start_link(__MODULE__, [])
  end

  def move_absolute(handler, pos, speed) do
    GenStage.call(handler, {:move_absolute, pos, speed})
  end

  def calibrate(handler, axis, speed) do
    GenStage.call(handler, {:calibrate, axis, speed})
  end

  def find_home(handler, axis, speed) do
    GenStage.call(handler, {:find_home, axis, speed})
  end

  def home(handler, axis, speed) do
    GenStage.call(handler, {:home, axis, speed})
  end

  def zero(handler, axis) do
    GenStage.call(handler, {:zero, axis})
  end

  def update_param(handler, param, val) do
    GenStage.call(handler, {:update_param, param, val})
  end

  def read_param(handler, param) do
    GenStage.call(handler, {:read_param, param})
  end

  def read_all_params(handler) do
    GenStage.call(handler, :read_all_params)
  end

  def emergency_lock(handler) do
    GenStage.call(handler, :emergency_lock)
  end

  def emergency_unlock(handler) do
    GenStage.call(handler, :emergency_unlock)
  end

  def read_pin(handler, pin, pin_mode) do
    GenStage.call(handler, {:read_pin, pin, pin_mode})
  end

  def write_pin(handler, pin, pin_mode, value) do
    GenStage.call(handler, {:write_pin, pin, pin_mode, value})
  end

  def request_software_version(handler) do
    GenStage.call(handler, :request_software_version)
  end

  ## Private

  defmodule State do
    @moduledoc false
    defstruct [
      nerves: nil,
      current_cmd: nil,
    ]
  end

  def init([]) do
    # If in dev environment, it is expected that this be done at compile time.
    # If ini target environment, this should be done by `Farmbot.Firmware.AutoDetector`.
    tty =
      Application.get_env(:farmbot, :uart_handler)[:tty] || raise "Please configure uart handler!"

    {:ok, nerves} = UART.start_link()
    Process.link(nerves)

    case open_tty(nerves, tty) do
      :ok -> {:producer, %State{nerves: nerves}, dispatcher: GenStage.BroadcastDispatcher}
      err -> {:stop, err, :no_state}
    end
  end

  defp open_tty(nerves, tty) do
    case UART.open(nerves, tty, speed: 115_200, active: true) do
      :ok ->
        :ok = configure_uart(nerves, true)
        # Flush the buffers so we start fresh
        :ok = UART.flush(nerves)
        :ok

      err ->
        err
    end
  end

  defp configure_uart(nerves, active) do
    UART.configure(
      nerves,
      framing: {Farmbot.Firmware.UartHandler.Framinig, separator: "\r\n"},
      active: active,
      rx_framing_timeout: 500
    )
  end

  # if there is an error, we assume something bad has happened, and we probably
  # Are better off crashing here, and being restarted.
  def handle_info({:nerves_uart, _, {:error, reason}}, state) do
    {:stop, {:error, reason}, state}
  end

  # Unhandled gcodes just get ignored.
  def handle_info({:nerves_uart, _, {:unhandled_gcode, code_str}}, state) do
    Logger.debug 3, "Got unhandled gcode: #{code_str}"
    {:noreply, [], state}
  end

  def handle_info({:nerves_uart, _, {:echo, _}}, %{current_cmd: nil} = state) do
    {:noreply, [], state}
  end
  def handle_info({:nerves_uart, _, {:echo, {:echo, "*F43" <> _}}}, state) do
    {:noreply, [], state}
  end

  def handle_info({:nerves_uart, _, {:echo, {:echo, code}}}, state) do
    distance = String.jaro_distance(state.current_cmd, code)
    if distance > 0.85 do
      :ok
    else
      Logger.error 3, "Echo does not match: got: #{code} expected: #{state.current_cmd} (#{distance})"
    end
    {:noreply, [], %{state | current_cmd: nil}}
  end

  def handle_info({:nerves_uart, _, {_q, :done}}, state) do
    {:noreply, [:done], %{state | current_cmd: nil}}
  end

  def handle_info({:nerves_uart, _, {_q, gcode}}, state) do
    {:noreply, [gcode], state}
  end

  def handle_info({:nerves_uart, _, bin}, state) when is_binary(bin) do
    Logger.warn(3, "Unparsed Gcode: #{bin}")
    {:noreply, [], state}
  end

  defp do_write(bin, state, dispatch \\ []) do
    case UART.write(state.nerves, bin) do
      :ok -> {:reply, :ok, dispatch, %{state | current_cmd: bin}}
      err -> {:reply, err, [], %{state | current_cmd: nil}}
    end
  end

  def handle_call({:move_absolute, pos, speed}, _from, state) do
    wrote = "G00 X#{pos.x} Y#{pos.y} Z#{pos.z} A#{speed} B#{speed} C#{speed}"
    do_write(wrote, state)
  end

  def handle_call({:calibrate, axis, _speed}, _from, state) do
    num = case axis |> to_string() do
      "x" -> 14
      "y" -> 15
      "z" -> 16
    end
    do_write("F#{num}", state)
  end

  def handle_call({:find_home, axis, speed}, _from, state) do
    cmd = case axis |> to_string() do
      "x" -> "11 A#{speed}"
      "y" -> "12 B#{speed}"
      "z" -> "13 C#{speed}"
    end
    do_write("F#{cmd}", state)
  end

  def handle_call({:home, axis, speed}, _from, state) do
    cmd = case axis |> to_string() do
      "x" -> "X0 A#{speed}"
      "y" -> "Y0 B#{speed}"
      "z" -> "Z0 C#{speed}"
    end
    do_write("G00 #{cmd}", state)
  end

  def handle_call({:zero, axis}, _from, state) do
    axis_format = case axis |> to_string() do
      "x" -> "X"
      "y" -> "Y"
      "z" -> "Z"
    end
    do_write("F84 #{axis_format}", state)
  end

  def handle_call(:emergency_lock, _from, state) do
    r = UART.write(state.nerves, "E")
    {:reply, r, [], state}
  end

  def handle_call(:emergency_unlock, _from, state) do
    do_write("F09", state)
  end

  def handle_call({:read_param, param}, _from, state) do
    num = Farmbot.Firmware.Gcode.Param.parse_param(param)
    do_write("F21 P#{num}", state)
  end

  def handle_call({:update_param, param, val}, _from, state) do
    num = Farmbot.Firmware.Gcode.Param.parse_param(param)
    do_write("F22 P#{num} V#{val}", state)
  end

  def handle_call(:read_all_params, _from, state) do
    do_write("F20", state)
  end

  def handle_call({:read_pin, pin, mode}, _from, state) do
    encoded_mode = if(mode == :digital, do: 0, else: 1)
    case UART.write(state.nerves, "F43 P#{pin} M#{encoded_mode}") do
      :ok ->
        do_write("F42 P#{pin} M#{encoded_mode}", state, [{:report_pin_mode, pin, mode}])
      err ->
        {:reply, err, [], %{state | current_cmd: nil}}
    end
  end

  def handle_call({:write_pin, pin, mode, value}, _from, state) do
    encoded_mode = if(mode == :digital, do: 0, else: 1)
    case UART.write(state.nerves, "F43 P#{pin} M#{encoded_mode}") do
      :ok ->
        do_write("F41 P#{pin} V#{value} M#{encoded_mode}", state, [{:report_pin_mode, pin, mode}, {:report_pin_value, pin, value}])
      err ->
        {:reply, err, [], %{state | current_cmd: nil}}
    end
  end

  def handle_call(:request_software_version, _from, state) do
    do_write("F83", state)
  end

  def handle_call(_call, _from, state) do
    {:reply, {:error, :bad_call}, [], state}
  end

  def handle_demand(_amnt, state) do
    {:noreply, [], state}
  end
end
