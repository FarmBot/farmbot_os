alias Experimental.{GenStage}
defmodule RPCMessageHandler do
  use GenStage
  require Logger
  @transport Application.get_env(:json_rpc, :transport)
  @update_server Application.get_env(:fb, :update_server)
  @doc """
    This is where all JSON RPC messages come in.
    Currently only from Mqtt, but is technically transport agnostic.
    Right now we set @transport to MqttHandler, but it could technically be
    In config and set to anything that can emit and recieve JSON RPC messages.
  """

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(_args) do
    {:consumer, :ok, subscribe_to: [RPCMessageManager]}
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
    IO.inspect({name, message})
    Poison.encode!(
    %{id: id,
      error: %{name: name,
               message: message },
      result: nil})
  end

  def log_msg(message) do
    Poison.encode!(
      %{ id: nil,
         method: "log_message",
         params: [%{status: BotStatus.get_status,
                    time: :os.system_time(:seconds),
                    message: message}] })
  end

  def personality_msg(message) when is_bitstring(message) do
      Poison.encode!(
      %{ id: nil,
         method: "personality_message",
         params: [%{message: message}] })
  end

  def handle_rpc(%{"method" => method, "params" => params, "id" => id})
  when is_list(params) and
       is_bitstring(method) and
       is_bitstring(id)
  do
    case do_handle(method, params) do
      :ok -> @transport.emit(ack_msg(id))
      {:error, name, message} -> @transport.emit(ack_msg(id, {name, message}))
      unknown_error -> @transport.emit(ack_msg(id, {"unknown_error", "#{inspect unknown_error}"}))
    end
  end

  def handle_rpc(broken_rpc) do
    Logger.debug("Got a broken RPC message!!")
    IO.inspect broken_rpc
  end

  # E STOP
  def do_handle("emergency_stop", _) do
    Command.e_stop
  end

  # Home All
  def do_handle("home_all", [ %{"speed" => s} ]) when is_integer s do
    Command.home_all(s)
  end

  def do_handle("home_all", params) do
    Logger.debug("bad params for home_all")
    IO.inspect(params)
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"speed" => "number"})}
  end

  # WRITE_PIN
  def do_handle("write_pin", [ %{"pin_mode" => 1, "pin_number" => p, "pin_value" => v} ])
    when is_integer p and
         is_integer v
  do
    Command.write_pin(p,v,1)
  end

  def do_handle("write_pin", [ %{"pin_mode" => 0, "pin_number" => p, "pin_value" => v} ])
    when is_integer p and
         is_integer v
  do
    Command.write_pin(p,v,0)
  end

  def do_handle("write_pin", _) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"pin_mode" => "1 or 2", "pin_number" => "number", "pin_value" => "number"})}
  end

  # Move to a specific coord
  def do_handle("move_absolute",  [%{"speed" => s, "x" => x, "y" => y, "z" => z}])
  when is_integer(x) and
       is_integer(y) and
       is_integer(z) and
       is_integer(s)
  do
    Command.move_absolute(x,y,z,s)
  end

  def do_handle("move_absolute",  params) do
    Logger.debug("bad params for Move Absolute")
    IO.inspect params
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
    Command.move_relative(%{x: x_move_by, y: y_move_by, z: z_move_by, speed: speed})
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
    case Fw.check_os_updates do
      :no_updates -> nil
       {:update, url} ->
         Logger.debug("NEW OS UPDATE")
         spawn fn -> Downloader.download_and_install_os_update(url) end
    end
    :ok
  end

  def do_handle("check_arduino_updates", _) do
    case Fw.check_fw_updates do
      :no_updates -> nil
       {:update, url} ->
          Logger.debug("NEW CONTROLLER UPDATE")
          spawn fn -> Downloader.download_and_install_fw_update(url) end
    end
    :ok
  end

  def do_handle("reboot", _ ) do
    log("Bot Going down for reboot in 5 seconds")
    spawn fn ->
      Process.sleep(5000)
      Nerves.Firmware.reboot
    end
    :ok
  end

  def do_handle("power_off", _ ) do
    log("Bot Going down in 5 seconds. Pls remeber me.")
    spawn fn ->
      Process.sleep(5000)
      Nerves.Firmware.poweroff
    end
    :ok
  end

#  "{\"update_calibration\", [%{\"movement_home_up_y\" => 0}]}"}
  def do_handle("update_calibration", [params]) when is_map(params) do
    case Enum.all?(params, fn({param, value}) ->
      param_int = Gcode.parse_param(param)
      Command.update_param(param_int, value)
    end)
    do
      true -> :ok
      false -> {:error, "update_calibration", "Something went wrong."}
    end
  end

  # Unhandled event. Probably not implemented if it got this far.
  def do_handle(event, params) do
    Logger.debug("[RPC_HANDLER] got valid rpc, but event is not implemented.")
    {:error, "Unhandled method", "#{inspect {event, params}}"}
  end

  @doc """
    Shortcut for loggin to teh frontend. Pass it a string, watch it display
  """
  def log(message) when is_bitstring(message) do
    @transport.emit(log_msg(message))
  end

  @doc """
    Shortcut for a personality message
  """
  def pm(message) when is_bitstring(message) do
    @transport.emit(personality_msg(message))
  end

  def send_status do
    m = %{id: nil,
          method: "status_update",
          params: [BotStatus.get_status] }
    @transport.emit(Poison.encode!(m))
  end
end
