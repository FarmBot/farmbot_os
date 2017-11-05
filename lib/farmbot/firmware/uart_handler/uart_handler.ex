defmodule Farmbot.Firmware.UartHandler do
  @moduledoc """
  Handles communication between farmbot and uart devices
  """

  use GenStage
  alias Nerves.UART
  require Logger

  def start_link do
    GenStage.start_link(__MODULE__, [])
  end

  def move_absolute(handler, pos, axis, speed) do
    GenStage.call(handler, {:move_absolute, pos, speed})
  end

  def calibrate(handler, axis, axis, speed) do
    GenStage.call(handler, {:calibrate, axis, speed})
  end

  def find_home(handler, axis, axis, speed) do
    GenStage.call(handler, {:find_home, axis, speed})
  end

  def home(handler, axis, speed) do
    GenStage.call(handler, {:home, axis, speed})
  end

  def zero(handler, axis, axis, speed) do
    GenStage.call(handler, {:zero, axis, speed})
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
      :nerves,
      :codes
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
      :ok -> {:producer, %State{nerves: nerves, codes: []}, dispatcher: GenStage.BroadcastDispatcher}
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
  def handle_info({:nerves_uart, _, {:unhandled_gcode, _code_str}}, state) do
    {:noreply, [], state}
  end

  def handle_info({:nerves_uart, _, {_q, gcode}}, state) do
    do_dispatch([gcode | state.codes], state)
  end

  def handle_info({:nerves_uart, _, bin}, state) when is_binary(bin) do
    Logger.warn("Unparsed Gcode: #{bin}")
    {:noreply, [], state}
  end

  def handle_demand(_amnt, state) do
    do_dispatch(state.codes, state)
  end

  defp do_dispatch(codes, state) do
    {:noreply, Enum.reverse(codes), %{state | codes: []}}
  end
end
