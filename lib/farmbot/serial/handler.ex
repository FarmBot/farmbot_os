defmodule Farmbot.Serial.Handler do
  @moduledoc """
    Handles serial messages and keeping ports alive.
  """
  require Logger
  @baud Application.get_env(:uart, :baud)

  defp open_serial(_pid, [], tries) do
    Logger.error("Could not auto detect serial port. I tried: #{inspect tries}")
    {:ok, "ttyFail"}
  end

  defp open_serial(pid, ports, tries) do
    [{tty,_} | rest] = ports
    case Nerves.UART.open(pid, tty, speed: @baud, active: true) do
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

  def init(:prod) do
    Process.flag(:trap_exit, true)
    {:ok, nerves} = Nerves.UART.start_link
    {:ok, handler} = Farmbot.Serial.Gcode.Handler.start_link(nerves)
    tty = open_serial(nerves)
    {:ok, {nerves, tty, handler}}
  end

  def init(:test) do
    Logger.warn("can some one please think of a better way to do this?")
    tty = "ttyFake"
    {:ok, test_nerves} = Nerves.FakeUART.start_link(self)
    {:ok, handler} = Farmbot.Serial.Gcode.Handler.start_link(test_nerves)
    {:ok, {test_nerves, tty, handler}}
  end

  def init(:dev) do
    Process.flag(:trap_exit, true)
    {:ok, nerves} = Nerves.UART.start_link
    tty = System.get_env("TTY")
    if tty == nil, do: raise "YOU FORGOT TO SET TTY ENV VAR"
    Nerves.UART.open(nerves, tty, speed: @baud, active: true)
    Nerves.UART.configure(nerves,
      framing: {Nerves.UART.Framing.Line,
                separator: "\r\n"},
                rx_framing_timeout: 500)


    {:ok, handler} = Farmbot.Serial.Gcode.Handler.start_link(nerves)
    {:ok, {nerves, tty, handler}}
  end

  def start_link(env) do
    GenServer.start_link(__MODULE__, env, name: __MODULE__)
  end

  @doc """
    Writes to a nerves uart tty. This only exists because
    I wanted to print what is being written
  """
  def write(str, caller)
  when is_bitstring(str) do
    Logger.debug("writing: #{str}")
    GenServer.cast(__MODULE__, {:write, str <> " Q0", caller})
  end

  # WHAT IS DOING THIS
  def write(_str, caller) do
    send(caller, :bad_type)
  end

  def e_stop do
    GenServer.call(__MODULE__, :e_stop)
  end

  def resume do
    GenServer.call(__MODULE__, :resume)
  end

  def handle_call(:e_stop, _from, {nerves, tty, handler}) do
    Nerves.UART.write(nerves, "E")
    Nerves.UART.close(nerves)
    # Temp hack to try to stop a running command.
    Nerves.UART.open(nerves, tty, speed: @baud, active: false)
    Nerves.UART.close(nerves)
    {:reply, :ok, {nerves, :e_stop, handler}}
  end


  def handle_call(:resume, _from, {nerves, :e_stop, handler}) do
    tty = open_serial(nerves)
    {:reply, :ok, {nerves, tty, handler}}
  end

  def handle_cast({:write, _str, caller}, {nerves, :e_stop, handler}) do
    send(caller, :e_stop)
    {:noreply, {nerves, :e_stop, handler}}
  end

  def handle_cast({:write, str, _caller}, {nerves, tty, handler}) do
    Nerves.UART.write(nerves, str)
    {:noreply, {nerves, tty, handler}}
  end

  # TODO Rewrite this with an Erlang Port
  def handle_cast({:update_fw, hex_file, pid}, {nerves, tty, handler}) do
    Nerves.UART.close(nerves)
    System.cmd("avrdude",
              ["-v",
               "-patmega2560",
               "-cwiring",
               "-P/dev/#{tty}",
               "-b115200",
               "-D",
               "-Uflash:w:#{hex_file}:i"]) |> parse_cmd(pid)
    new_tty = open_serial(nerves)
    {:noreply, {nerves, new_tty, handler}}
  end

  # WHEN A FULL SERIAL MESSAGE COMES IN.
  def handle_info({:nerves_uart, nerves_tty, message}, {pid, tty, handler})
  when is_binary(message) and nerves_tty == tty do
    gcode = Farmbot.Serial.Gcode.Parser.parse_code(String.strip(message))
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
    Farmbot.Logger.log("Serial disconnected!", [:error_toast, :error_ticker], ["SERIAL"])
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _tty, _event}, {nerves, :e_stop, handler}) do
    Logger.warn("IN E STOP MODE!")
    {:noreply, {nerves, :e_stop, handler}}
  end

  def handle_info({:nerves_uart, _tty, event}, state) do
    Logger.debug("Nerves UART Event: #{inspect event}")
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, pid, reason}, {nerves, tty, handler})
  when pid == handler do
      Logger.debug "gcode handler died: #{inspect reason}"
      {:ok, restarted} = Farmbot.Serial.Gcode.Handler.start_link(nerves)
      {:noreply,  {nerves, tty, restarted}}
  end

  def handle_info({:EXIT, pid, reason}, {nerves, tty, handler})
  when pid == nerves do
    Logger.debug "Nerves UART died: #{inspect reason}"
    {:crashme,  {nerves, tty, handler}}

  end

  def handle_info({:EXIT, pid, reason}, state) do
    Logger.debug("EXIT IN #{inspect pid}: #{inspect reason}")
    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.debug "info: #{inspect event}"
    {:noreply, state}
  end

  @spec parse_cmd({String.t, integer}, pid) :: :ok
  defp parse_cmd({_, 0}, pid), do: send(pid, :done)
  defp parse_cmd({output, _}, pid), do: send(pid, {:error, output})

  def terminate(:restart, {nerves, _tty, handler}) do
    GenServer.stop(nerves, :normal)
    GenServer.stop(handler, :normal)
  end

  def terminate(reason, state) do
    Logger.debug("UART HANDLER DIED.")
    Logger.debug("#{inspect reason}: #{inspect state}")
  end
end
