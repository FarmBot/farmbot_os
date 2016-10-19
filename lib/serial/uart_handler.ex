defmodule UartHandler do
  require Logger
  @baud Application.get_env(:uart, :baud)

  defp open_serial(_pid, [], tries) do
    Logger.error("Could not auto detect serial port. I tried: #{inspect tries}")
    {:ok, "ttyFail"}
  end

  defp open_serial(pid, ports, tries) do
    [{tty, _ } | rest ] = ports
    blah = Nerves.UART.open(pid, tty, speed: @baud, active: true)
    case blah do
      :ok -> {:ok, tty}
      _ -> open_serial(pid, rest, tries ++ [tty])
    end
  end

  defp open_serial(pid) do
    {:ok, tty} = open_serial(pid, list_ttys , []) # List of available ports
    Nerves.UART.configure(pid, framing: {Nerves.UART.Framing.Line, separator: "\r\n"}, rx_framing_timeout: 500)
    tty
  end

  def list_ttys do
    Nerves.UART.enumerate
    |> Map.drop(["ttyS0","ttyAMA0"])
    |> Map.to_list
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, pid} = Nerves.UART.start_link
    {:ok, handler} = NewHandler.start_link(pid)
    tty = open_serial(pid)
    {:ok, {pid, tty, handler}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def handle_cast({:send, _str}, {pid, "ttyFail", handler}) do
    {:noreply, {pid,"ttyFail", handler}}
  end

  def handle_cast({:send, str}, {pid, tty, handler}) do
    Nerves.UART.write(pid, str)
    {:noreply, {pid,tty, handler}}
  end

  # WHEN A FULL SERIAL MESSAGE COMES IN.
  def handle_info({:nerves_uart, _tty, message}, {pid, tty, handler}) when is_binary(message) do
    # GenServer.cast(UartHandler, {:send, "F22 P0 V0"})
    gcode = Gcode.parse_code(String.strip(message))
    GenServer.cast(handler, gcode)
    {:noreply, {pid, tty, handler}}
  end

  def handle_info({:nerves_uart, _tty, {:partial, partial}}, state) do
    Logger.debug("Partial code: #{partial}")
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _tty, event}, state) do
    Logger.debug("Serial Event: #{inspect event}")
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, pid, reason}, state) do
    Logger.debug("EXIT IN #{inspect pid}: #{inspect reason}")
    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.debug "info: #{inspect event}"
    {:noreply, state}
  end

  def terminate(reason, other) do
    Logger.debug("UART HANDLER DIED.")
    Logger.debug("#{inspect reason}: #{inspect other}")
  end
end
