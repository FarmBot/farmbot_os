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

  def handle_cast({:update_fw, hex_file}, {nerves, tty, handler}) do
    Nerves.UART.close(nerves)
    System.cmd("avrdude", ["-v", "-patmega2560", "-cwiring", "-P/dev/#{tty}", "-b115200", "-D", "-Uflash:w:#{hex_file}:i"])
    new_tty = open_serial(nerves)
    RPCMessageHandler.log("Updated FW", [:success_toast, :ticker], ["UartHandler"])
    {:noreply, {nerves, new_tty, handler}}
  end

  def handle_call(:e_stop, _from, {pid, tty, handler}) do
    write(pid, "E")
    raise "E STOP"
    Process.exit(pid, "asdf")
    Process.exit(handler, :e_stop)
    {:reply, :ok, {pid, tty, handler}}
  end

  @doc """
    Writes to a nerves uart tty. This only exists because
    I wanted to print what is being written
  """
  def write(pid, str) do
    Logger.debug("writing: #{str}")
    Nerves.UART.write(pid, str<>" Q0")
  end

  # WHEN A FULL SERIAL MESSAGE COMES IN.
  def handle_info({:nerves_uart, nerves_tty, message}, {pid, tty, handler})
  when is_binary(message) and nerves_tty == tty do
    gcode = Gcode.parse_code(String.strip(message))
    GenServer.cast(handler, gcode)
    {:noreply, {pid, tty, handler}}
  end

  def handle_info({:nerves_uart, _nerves_tty, message}, {pid, tty, handler})
  when is_binary(message) do
    Logger.debug("Something weird has happened.")
    {:noreply, {pid, tty, handler}}
  end

  def handle_info({:nerves_uart, _tty, {:partial, partial}}, state) do
    Logger.debug("Partial code: #{partial}")
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _tty, {:error, :eio}}, state) do
    RPCMessageHandler.log("Serial disconnected!", [:error_toast, :error_ticker], ["SERIAL"])
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _tty, event}, state) do
    Logger.debug("Nerves UART Event: #{inspect event}")
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, :e_stop}, {nerves, tty, handler}) do
    Logger.debug("E STOPPING")
    Nerves.UART.close(nerves)
    Process.exit(self(), :real_e_stop)
    {:noreply, {nerves, tty, handler}}
  end

  def handle_info({:EXIT, pid, reason}, {nerves, tty, handler}) do
    if(pid == handler) do
      Logger.debug "gcode handler died: #{inspect reason}"
      {:ok, restarted} = NewHandler.start_link(nerves)
      {:noreply,  {nerves, tty, restarted}}
    else
      {:noreply,  {nerves, tty, handler}}
    end
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
