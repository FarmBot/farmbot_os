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

  ## Private

  defmodule State do
    @moduledoc false
    defstruct [
      :nerves
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

  def handle_info({:nerves_uart, _, {_q, gcode}}, state) do
    {:noreply, [gcode], state}
  end

  def handle_info({:nerves_uart, _, bin}, state) when is_binary(bin) do
    Logger.warn(3, "Unparsed Gcode: #{bin}")
    {:noreply, [], state}
  end

  def handle_call({:move_absolute, pos, speed}, _from, state) do
    r = UART.write(state.nerves, "G00 X#{pos.x} Y#{pos.y} Z#{pos.z} A#{speed} B#{speed} C#{speed}")
    {:reply, r, [], state}
  end

  def handle_call({:calibrate, axis, _speed}, _from, state) do
    num = case axis |> to_string() do
      "x" -> 14
      "y" -> 15
      "z" -> 16
    end
    r = UART.write(state.nerves, "F#{num}")
    {:reply, r, [], state}
  end

  def handle_call({:find_home, axis, speed}, _from, state) do
    cmd = case axis |> to_string() do
      "x" -> "11 A#{speed}"
      "y" -> "12 B#{speed}"
      "z" -> "13 C#{speed}"
    end
    r = UART.write(state.nerves, "F#{cmd}")
    {:reply, r, [], state}
  end

  def handle_call({:home, axis, speed}, _from, state) do
    cmd = case axis |> to_string() do
      "x" -> "X0 A#{speed}"
      "y" -> "Y0 B#{speed}"
      "z" -> "Z0 C#{speed}"
    end
    r = UART.write(state.nerves, "G00 #{cmd}")
    {:reply, r, [], state}
  end

  def handle_call({:zero, axis}, _from, state) do
    axis_format = case axis |> to_string() do
      "x" -> "X"
      "y" -> "Y"
      "z" -> "Z"
    end
    r = UART.write(state.nerves, "F84 #{axis_format}")
    {:reply, r, [], state}
  end

  def handle_call(:emergency_lock, _from, state) do
    r = UART.write(state.nerves, "E")
    {:reply, r, [], state}
  end

  def handle_call(:emergency_unlock, _from, state) do
    r = UART.write(state.nerves, "F09")
    {:reply, r, [], state}
  end

  def handle_call({:read_pin, pin, mode}, _from, state) do
    encoded_mode = if(mode == :digital, do: 0, else: 1)
    case UART.write(state.nerves, "F43 P#{pin} M#{encoded_mode}") do
      :ok ->
        Process.sleep(100)
        r = UART.write(state.nerves, "F42 P#{pin} M#{encoded_mode}")
        {:reply, r, [{:report_pin_mode, pin, mode}], state}
      err ->
        {:reply, err, [], state}
    end
  end

  def handle_call({:write_pin, pin, mode, value}, _from, state) do
    encoded_mode = if(mode == :digital, do: 0, else: 1)
    case UART.write(state.nerves, "F43 P#{pin} M#{encoded_mode}") do
      :ok ->
        Process.sleep(100)
        r = UART.write(state.nerves, "F41 P#{pin} V#{value} M#{encoded_mode}")
        {:reply, r, [{:report_pin_mode, pin, mode}, {:report_pin_value, pin, value}], state}
      err ->
        {:reply, err, [], state}
    end
  end

  def handle_call(_call, _from, state) do
    {:reply, {:error, :bad_call}, [], state}
  end

  def handle_demand(_amnt, state) do
    {:noreply, [], state}
  end
end
