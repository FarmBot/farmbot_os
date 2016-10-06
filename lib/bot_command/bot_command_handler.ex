defmodule BotCommandHandler do
  require Logger
  use GenServer

  @moduledoc """
    This is the log mechanism for bot commands.
  """

  def init(_args) do
    {:ok, pid} = GenEvent.start_link(name: BOTEVENTMANAGER)
    GenEvent.add_handler(pid, BotCommandManager, [{:not_doing_stuff, []}])
    spawn fn -> get_events(pid) end
    {:ok, pid}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_cast({:add_event, event}, pid) do
    GenEvent.notify(pid, event)
    {:noreply, pid}
  end

  def handle_call(:get_pid, _from,  pid) do
    {:reply, pid, pid}
  end

  def handle_call(:e_stop, _from, pid) do
    GenEvent.notify(pid, :e_stop)
    {:reply, :ok, pid}
  end

  def get_pid do
    GenServer.call(__MODULE__, :get_pid, 5000)
  end

  def e_stop do
    GenServer.call(__MODULE__, :e_stop, 5000)
  end

  @doc """
    Gets events from the GenEvent server (pid)
  """
  def get_events(pid) do
    events = GenEvent.call(pid, BotCommandManager, :events)
    for event <- events do
      Process.sleep(150)
      check_busy
      BotStatus.busy true
      do_handle(event)
      Process.sleep(50)
    end
    GenEvent.call(pid, BotCommandManager, :done_doing_stuff)
    get_events(pid)
  end

  defp check_busy do
    case BotStatus.busy? do
      true -> check_busy
      false -> :ok
    end
  end

  def notify(event) do
    GenServer.cast(__MODULE__, {:add_event, event})
  end

  ###
  ## This might not be the best implementation.
  ## PROBLEM: There is a small chance for the bot to be out of sync from the
  ##          Arduino.
  ##
  ## EXAMPLE: If Farmbot recieves a command and sends it properly over UART
  ##          but the Arduino decides for any reason to not accept that command,
  ##          Farmbot and the frontend think the bot is at one position
  ##          and the actual bot is at a different position.
  ###

  defp do_handle({:home_x, {_speed}}) do
    Logger.info("HOME X")
    SerialMessageManager.sync_notify( {:send, "F11"} )
  end

  defp do_handle({:home_y, {_speed}}) do
    Logger.info("HOME Y")
    SerialMessageManager.sync_notify( {:send, "F12"} )
  end

  defp do_handle({:home_z, {_speed}}) do
    Logger.info("HOME Z")
    SerialMessageManager.sync_notify( {:send, "F13"} )
  end

  # These need to be "safe" commands. IE they shouldnt crash anythin.
  defp do_handle({:write_pin, {pin, value, mode}}) do
    Logger.info("WRITE_PIN " <> "F41 P#{pin} V#{value} M#{mode}")
    SerialMessageManager.sync_notify( {:send, "F41 P#{pin} V#{value} M#{mode}"} )
  end

  defp do_handle({:move_absolute, {x,y,z,_s}}) do
    Logger.info("MOVE_ABSOLUTE " <> "G00 X#{x} Y#{y} Z#{z}")
    SerialMessageManager.sync_notify( {:send, "G00 X#{x} Y#{y} Z#{z}"} )
  end

  defp do_handle({:read_param, param}) do
    Logger.info("READ_PARAM "<> "#{param}")
    SerialMessageManager.sync_notify({:send, "F21 P#{param}" })
  end

  defp do_handle({:read_pin, {pin, mode}}) do
    Logger.info("READ PIN "<> "#{pin}")
    SerialMessageManager.sync_notify({:send, "F42 P#{pin} M#{mode}" })
  end

  defp do_handle({:update_param, {param, value}}) do
    Logger.info("UPDATE PARAM " <> "#{param} #{value}")
    SerialMessageManager.sync_notify({:send, "F22 P#{param} V#{value}"})
  end

  defp do_handle({method, params}) do
    Logger.debug("Unhandled method: #{inspect method} with params: #{inspect params}")
  end

  # Unhandled event. Probably not implemented if it got this far.
  defp do_handle(event) do
    Logger.debug("[Command Handler] (Probably not implemented) Unhandled Event: #{inspect event}")
  end
end
