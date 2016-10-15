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
    {:ok, pid} = Nerves.UART.start_link
    tty = open_serial(pid)
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

  def send("E") do
    GenServer.call(__MODULE__, {:send, "E"})
  end

  def send(str) do
    GenServer.cast(__MODULE__, {:send, str})
  end

  # Genserver Calls
  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end


  def handle_call({:send, "E"}, _from, {pid, tty}) do
    Nerves.UART.write(pid, "E")
    {:reply, :ok, {pid, tty}}
  end

  def handle_cast({:send, str}, {pid, "ttyFail"}) do
    new_tty = open_serial(pid)
    BotStatus.busy false
    case Nerves.UART.write(pid, str) do
      {:error, :ebadf} -> {:noreply, {pid, "ttyFail"}}
      :ok ->
        RPCMessageHandler.log("Reconnected to Arduino!",
                              ["success_toast", "ticker"])
        {:noreply, {pid, new_tty}}
    end
  end

  def handle_cast({:send, str}, {pid, tty}) do
    case Nerves.UART.write(pid, str) do
      {:error, :ebadf} -> {:noreply, {pid, "ttyFail"}}
      :ok -> {:noreply, {pid, tty}}
    end
  end

  def handle_cast({:connect, tty, baud, active}, state) do
    Nerves.UART.open(state, tty, speed: baud, active: active)
    Nerves.UART.configure(state, framing: {Nerves.UART.Framing.Line, separator: "\r\n"}, rx_framing_timeout: 500)
    {:noreply, state}
  end

  # WHEN A FULL SERIAL MESSAGE COMES IN.
  def handle_info({:nerves_uart, _tty, message}, state) when is_bitstring(message) do
    gcode = Gcode.parse_code(String.strip(message))
    SerialMessageManager.sync_notify({:gcode, gcode })
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _tty, {:error, :eio}}, {pid, tty}) do
    Logger.debug("Serial port lost")
    RPCMessageHandler.log("Please plug my arduino back in!", ["error_toast", "error_ticker"])
    {:noreply, {pid,tty}}
  end

  def handle_info({:nerves_uart, "ttyFail", {:error, :ebadf}}, {pid, _ftty}) do
    new_tty = open_serial(pid)
    BotStatus.busy false
    if(new_tty != "ttyFail") do
      Command.read_all_params
      Command.read_all_pins
      RPCMessageHandler.log("Reconnected to Arduino!",
                            ["success_toast", "ticker"])
    end
    {:noreply, {pid, new_tty}}
  end

  def handle_info({:nerves_uart, _tty, {:error, :ebadf}}, {pid, _ftty}) do
    RPCMessageHandler.log("Could not communicate with arduino.
                           Please plug it back in and try again.",
                          ["error_toast", "error_ticker"])
    new_tty = open_serial(pid)
    BotStatus.busy false
    if(new_tty != "ttyFail") do
      Command.read_all_params
      Command.read_all_pins
      RPCMessageHandler.log("Reconnected to Arduino!",
                            ["success_toast", "ticker"])
    end
    {:noreply, {pid, new_tty}}
  end

  def handle_info({:nerves_uart, _tty, event}, state) do
    Logger.debug("Serial Event: #{inspect event}")
    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.debug "info: #{inspect event}"
    {:noreply, state}
  end

  def terminate(reason, other) do
    Logger.debug("UART HANDLER CRASHED.")
    Logger.debug("#{inspect reason}: #{inspect other}")
  end
end
