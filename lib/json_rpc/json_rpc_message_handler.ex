alias Experimental.{GenStage}
defmodule RPC.MessageHandler do
  use GenStage
  require Logger
  @transport Application.get_env(:json_rpc, :transport)
  @update_server Application.get_env(:fb, :update_server)
  @doc """
    This is where all JSON RPC messages come in.
    Currently only from Mqtt, but is technically transport agnostic.
    Right now we set @transport to Mqtt.Handler, but it could technically be
    In config and set to anything that can emit and recieve JSON RPC messages.
  """

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(_args) do
    {:consumer, :ok, subscribe_to: [RPC.MessageManager]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      handle_rpc(event)
    end
    {:noreply, [], state}
  end

  # JSON RPC RESPONSE
  def ack_msg(id) when is_bitstring(id) do
    Poison.encode!(
    %{id: id,
      error: nil,
      result: %{"OK" => "OK"} })
  end

  # JSON RPC RESPONSE ERROR
  def ack_msg(id, {name, message}) when is_bitstring(id) and is_bitstring(name) and is_bitstring(message) do
    Logger.error("RPC ERROR")
    Logger.debug("#{inspect {name, message}}")
    Poison.encode!(
    %{id: id,
      error: %{name: name,
               message: message },
      result: nil})
  end

  @doc """
    Logs a message to the frontend.
  """
  def log_msg(message, channels, tags)
  when is_list(channels)
       and is_list(tags)
       and is_bitstring(message) do
    Poison.encode!(
      %{ id: nil,
         method: "log_message",
         params: [%{ status: BotState.get_status,
                     time: :os.system_time(:seconds),
                     message: message,
                     channels: channels,
                     tags: tags }] })
  end

  def handle_rpc(%{"method" => method, "params" => params, "id" => id})
  when is_list(params) and
       is_bitstring(method) and
       is_bitstring(id)
  do
    case do_handle(method, params) do
      :ok -> @transport.emit(ack_msg(id))
      {:error, name, message} -> @transport.emit(ack_msg(id, {name, message}))
    end
  end

  def handle_rpc(broken_rpc) do
    Logger.debug("Got a broken RPC message!!")
    Logger.debug("#{inspect broken_rpc}")
  end

  # E STOP
  def do_handle("emergency_stop", _) do
    Command.e_stop
    :ok
  end

  # Home All
  def do_handle("home_all", [ %{"speed" => s} ]) when is_integer s do
    spawn fn -> Command.home_all(s) end
    :ok
  end

  def do_handle("home_all", _params) do
    Logger.debug("bad params for home_all")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"speed" => "number"})}
  end

  # WRITE_PIN
  def do_handle("write_pin", [ %{"pin_mode" => 1, "pin_number" => p, "pin_value" => v} ])
    when is_integer(p) and
         is_integer(v)
  do
    spawn fn -> Command.write_pin(p,v,1) end
    :ok
  end

  def do_handle("write_pin", [ %{"pin_mode" => 0, "pin_number" => p, "pin_value" => v} ])
    when is_integer p and
         is_integer v
  do
    spawn fn -> Command.write_pin(p,v,0) end
    :ok
  end

  def do_handle("write_pin", _) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"pin_mode" => "1 or 2", "pin_number" => "number", "pin_value" => "number"})}
  end

  def do_handle("toggle_pin", [%{"pin_number" => p}]) when is_integer(p) do
    spawn fn -> Command.toggle_pin(p) end
    :ok
  end

  def do_handle("toggle_pin", params) do
    Logger.error ("#{inspect params}")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"pin_number" => "number"})}
  end

  # Move to a specific coord
  def do_handle("move_absolute",  [%{"speed" => s, "x" => x, "y" => y, "z" => z}])
  when is_integer(x) and
       is_integer(y) and
       is_integer(z) and
       is_integer(s)
  do
    spawn fn -> Command.move_absolute(x,y,z,s) end
    :ok
  end

  def do_handle("move_absolute",  _params) do
    Logger.debug("bad params for Move Absolute")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"x" => "number", "y" => "number", "z" => "number", "speed" => "number"})}
  end

  # Move relative to current x position
  def do_handle("move_relative", [%{"speed" => speed,
                                    "x" => x_move_by,
                                    "y" => y_move_by,
                                    "z" => z_move_by}])
    when is_integer(speed) and
         is_integer(x_move_by) and
         is_integer(y_move_by) and
         is_integer(z_move_by)
  do
    spawn fn -> Command.move_relative(%{x: x_move_by, y: y_move_by, z: z_move_by, speed: speed}) end
    :ok
  end

  def do_handle("move_relative", _) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"x or y or z" => "number to move by", "speed" => "number"})}
  end

  # Read status
  def do_handle("read_status", _) do
    Logger.debug("Reporting Current Status")
    send_status
  end

  def do_handle("check_updates", _) do
    Fw.check_and_download_os_update
    :ok
  end

  def do_handle("check_arduino_updates", _) do
    Fw.check_and_download_fw_update
    :ok
  end

  def do_handle("reboot", _ ) do
    log("Bot Going down for reboot in 5 seconds", [], ["BotControl"])
    spawn fn ->
      log("Rebooting!", [:ticker, :warning_toast], ["BotControl"])
      Process.sleep(5000)
      Nerves.Firmware.reboot
    end
    :ok
  end

  def do_handle("power_off", _ ) do
    log("Bot Going down in 5 seconds. Pls remeber me.")
    spawn fn ->
      log("Powering Down!", [:ticker, :warning_toast], ["BotControl"])
      Process.sleep(5000)
      Nerves.Firmware.poweroff
    end
    :ok
  end

  def do_handle("mcu_config_update", [params]) when is_map(params) do
    case Enum.partition(params, fn({param, value}) ->
      param_int = Gcode.Parser.parse_param(param)
      spawn fn -> Command.update_param(param_int, value) end
    end)
    do
      {_, []} ->
        log("MCU params updated.", [:success_toast], ["RPCHANDLER"])
        send_status
        :ok
      {_, failed} ->
        log("MCU params failed: #{inspect failed}", [:error_toast], ["RPCHANDLER"])
        send_status
        :ok
    end
  end

  def do_handle("bot_config_update", [configs]) do
    case Enum.partition(configs, fn({config, value}) ->
      BotState.update_config(config, value)
    end) do
      {_, []} ->
        log("Bot Configs updated.", [:success_toast], ["RPCHANDLER"])
        send_status
        :ok
      {_, failed} ->
        log("Bot Configs failed: #{inspect failed}", [:error_toast], ["RPCHANDLER"])
        send_status
        :ok
    end
  end

  def do_handle("sync", _) do
    BotSync.sync
    :ok
  end

  def do_handle("exec_sequence", [sequence]) do
    Map.drop(sequence, ["dirty"])
    |> Map.merge(%{"device_id" => -1, "id" => Map.get(sequence, "id") || -1})
    |> Sequence.create
    |> Farmbot.Scheduler.add_sequence
  end

  def do_handle("start_regimen", [%{"regimen_id" => id}]) when is_integer(id) do
    BotSync.sync()
    regimen = BotSync.get_regimen(id)
    Farmbot.Scheduler.add_regimen(regimen)
    send_status
  end

  def do_handle("start_regimen", params) do
    Logger.debug("bad params for start_regimen: #{inspect params}")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"regimen_id" => "number"})}
  end

  def do_handle("stop_regimen", [%{"regimen_id" => id}]) when is_integer(id) do
    regimen = BotSync.get_regimen(id)
    {pid, ^regimen, _, _} = GenServer.call(Farmbot.Scheduler, :state)
    |> Map.get(:running_regimens)
    |> Enum.find(fn({_pid, re, _items, _start_time}) ->
      re == regimen
    end)
    send(Farmbot.Scheduler, {:done, {:regimen, pid, regimen}})
    :ok
  end

  def do_handle("stop_regimen", params) do
    Logger.debug("bad params for stop_regimen: #{inspect params}")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"regimen_id" => "number"})}
  end



  # Unhandled event. Probably not implemented if it got this far.
  def do_handle(event, params) do
    Logger.debug("[RPC_HANDLER] got valid rpc, but event is not implemented.")
    {:error, "Unhandled method", "#{inspect {event, params}}"}
  end

  @doc """
    Shortcut for logging a message to the frontend.
    =  Channel can be  =
    |  :error_ticker   |
    |  :error_toast    |
    |  :success_toast  |
    |  :warning_toast  |
  """
  def log(message, channel \\ [], tags \\ [])
  def log(message, channels, tags)
  when is_bitstring(message)
   and is_list(channels)
   and is_list(tags) do
     v = log_msg(message, channels, tags)
    @transport.emit(v)
  end

  # This is what actually updates the rest of the world about farmbots status.
  def send_status do
    status =
      Map.merge(BotState.get_status,
      %{ farm_events: GenServer.call(Farmbot.Scheduler, :jsonable) })
    m = %{id: nil,
          method: "status_update",
          params: [status] }
    @transport.emit(Poison.encode!(m))
  end
end
