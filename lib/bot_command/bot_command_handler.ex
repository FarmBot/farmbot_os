defmodule BotCommandHandler do
  require Logger
  use GenServer

  @moduledoc """
    This is the log mechanism for bot commands.
  """

  def init(_args) do
    Process.flag(:trap_exit, true)
    {:ok, manager} = GenEvent.start_link(name: BotCommandEventManager)
    GenEvent.add_handler(manager, BotCommandManager, [])
    handler = spawn_link fn -> get_events(manager) end
    {:ok, {manager,handler}}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_cast({:add_event, event}, {manager,handler}) do
    GenEvent.notify(manager, event)
    {:noreply, {manager,handler}}
  end

  def handle_call(:get_pid, _from,  {manager,handler}) do
    {:reply, manager, {manager,handler}}
  end

  def handle_call(:e_stop, _from, {manager,handler}) do
    Process.flag(:trap_exit, true)
    GenEvent.notify(manager, :e_stop)
    Process.exit(handler, :e_stop)
    {:reply, :ok, {manager,handler}}
  end

  def handle_info({:EXIT, _pid, reason}, {manager,_handler}) do
    Logger.debug("something bad happened in #{__MODULE__}: #{inspect reason}")
    new_pid = spawn_link fn -> get_events(manager) end
    {:noreply, {manager, new_pid}}
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
  def get_events(manager) when is_pid(manager) do
    events = GenEvent.call(manager, BotCommandManager, :events)
    do_events(events)
    get_events(manager)
  end

  def do_events([]) do
    do_events(nil)
  end

  def do_events(nil) do
    Process.sleep(10)
  end

  def do_events(events) when is_list(events) do
    event = List.first(events)
    Process.sleep(150)
    check_busy
    BotStatus.busy true
    do_handle(event)
    Process.sleep(50)
    do_events(events -- [event])
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
    Logger.debug("HOME X")
    SerialMessageManager.sync_notify( {:send, "F11"} )
  end

  defp do_handle({:home_y, {_speed}}) do
    Logger.debug("HOME Y")
    SerialMessageManager.sync_notify( {:send, "F12"} )
  end

  defp do_handle({:home_z, {_speed}}) do
    Logger.debug("HOME Z")
    SerialMessageManager.sync_notify( {:send, "F13"} )
  end

  # These need to be "safe" commands. IE they shouldnt crash anythin.
  defp do_handle({:write_pin, {pin, value, mode}}) do
    Logger.debug("WRITE_PIN " <> "F41 P#{pin} V#{value} M#{mode}")
    SerialMessageManager.sync_notify( {:send, "F41 P#{pin} V#{value} M#{mode}"} )
  end

  defp do_handle({:move_absolute, {x,y,z,s}}) do
    Logger.debug("MOVE_ABSOLUTE " <> "G00 X#{x} Y#{y} Z#{z} S#{s}")
    SerialMessageManager.sync_notify( {:send, "G00 X#{x} Y#{y} Z#{z} S#{s}"} )
  end

  defp do_handle({:read_param, param}) do
    Logger.debug("READ_PARAM "<> "#{param}")
    SerialMessageManager.sync_notify({:send, "F21 P#{param}" })
  end

  defp do_handle({:read_pin, {pin, mode}}) do
    Logger.debug("READ PIN "<> "#{pin}")
    SerialMessageManager.sync_notify({:send, "F42 P#{pin} M#{mode}" })
  end

  defp do_handle({:update_param, {param, value}}) do
    Logger.debug("UPDATE PARAM " <> "#{param} #{value}")
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
