defmodule UartHandler do
  require Logger
  @tty Application.get_env(:uart, :tty)
  @baud Application.get_env(:uart, :baud)

  defp open_serial(_pid, [], tries) do
    Logger.debug("Could not auto detect serial port.")
    Logger.debug("I tried: #{inspect tries}")
    Process.exit(self(), :kill)
  end

  defp open_serial(pid, ports, tries) do
    [{tty, _ } | rest ] = ports
    blah = Nerves.UART.open(pid, tty, speed: @baud, active: true)
    case blah do
      :ok -> {:ok, tty}
      _ -> open_serial(pid, rest, tries ++ [tty])
    end
  end

  def init(_) do
    {:ok, pid} = Nerves.UART.start_link
    {:ok, tty} = open_serial(pid, Nerves.UART.enumerate |>
                     Map.drop(["ttyS0","ttyAMA0"]) |>
                     Map.to_list, []) # List of available ports
    Nerves.UART.configure(pid, framing: {Nerves.UART.Framing.Line, separator: "\r\n"}, rx_framing_timeout: 500)
    {:ok, {pid, tty}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def nerves do
    GenServer.call(__MODULE__, {:get_state})
  end

  def connect(tty, baud, active \\ true) do
    GenServer.cast(__MODULE__, {:connect, tty, baud, active})
  end

  def send(str) do
    GenServer.cast(__MODULE__, {:send, str})
  end

  # Genserver Calls
  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:connect, tty, baud, active}, state) do
    Nerves.UART.open(state, tty, speed: baud, active: active)
    Nerves.UART.configure(state, framing: {Nerves.UART.Framing.Line, separator: "\r\n"}, rx_framing_timeout: 500)
    {:noreply, state}
  end

  def handle_cast({:send, str}, {pid, tty}) do
    Nerves.UART.write(pid, str)
    {:noreply,  {pid, tty}}
  end

  def handle_info({:nerves_uart, _tty, {:error, _}}, state) do
    nil
    {:noreply, state}
  end

  # WHEN A FULL SERIAL MESSAGE COMES IN.
  def handle_info({:nerves_uart, _tty, message}, state) do
    gcode = Gcode.parse_code(String.strip(message))
    SerialMessageManager.sync_notify({:gcode, gcode })
    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.debug "info: #{inspect event}"
    {:noreply, state}
  end

  def terminate(reason, other) do
    Logger.debug("UART HANDLER CRASHED. Trying to restart?")
    Logger.debug("#{inspect reason}: #{inspect other}")
  end
end
