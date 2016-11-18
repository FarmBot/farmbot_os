defmodule Farmbot.RPC.Requests do
  require Logger

  # E STOP
  def handle_request("emergency_lock", _) do
    Command.e_stop
    :ok
  end

  # Home All
  def handle_request("home_all", [ %{"speed" => s} ]) when is_integer s do
    spawn fn -> Command.home_all(s) end
    :ok
  end

  def handle_request("home_all", _params) do
    Logger.debug("bad params for home_all")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"speed" => "number"})}
  end

  # WRITE_PIN
  def handle_request("write_pin", [ %{"pin_mode" => 1, "pin_number" => p, "pin_value" => v} ])
    when is_integer(p) and
         is_integer(v)
  do
    spawn fn -> Command.write_pin(p,v,1) end
    :ok
  end

  def handle_request("write_pin", [ %{"pin_mode" => 0, "pin_number" => p, "pin_value" => v} ])
    when is_integer p and
         is_integer v
  do
    spawn fn -> Command.write_pin(p,v,0) end
    :ok
  end

  def handle_request("write_pin", _) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"pin_mode" => "1 or 2", "pin_number" => "number", "pin_value" => "number"})}
  end

  def handle_request("toggle_pin", [%{"pin_number" => p}]) when is_integer(p) do
    spawn fn -> Command.toggle_pin(p) end
    :ok
  end

  def handle_request("toggle_pin", params) do
    Logger.error ("#{inspect params}")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"pin_number" => "number"})}
  end

  # Move to a specific coord
  def handle_request("move_absolute",  [%{"speed" => s, "x" => x, "y" => y, "z" => z}])
  when is_integer(x) and
       is_integer(y) and
       is_integer(z) and
       is_integer(s)
  do
    spawn fn -> Command.move_absolute(x,y,z,s) end
    :ok
  end

  def handle_request("move_absolute",  _params) do
    Logger.debug("bad params for Move Absolute")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"x" => "number", "y" => "number", "z" => "number", "speed" => "number"})}
  end

  # Move relative to current x position
  def handle_request("move_relative", [%{"speed" => speed,
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

  def handle_request("move_relative", _) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"x or y or z" => "number to move by", "speed" => "number"})}
  end

  # Read status
  def handle_request("read_status", _) do
    Logger.debug("Reporting Current Status")
    # FIXME
  end

  def handle_request("check_updates", _) do
    Downloader.check_and_download_os_update
    :ok
  end

  def handle_request("check_arduino_updates", _) do
    Downloader.check_and_download_fw_update
    :ok
  end

  def handle_request("reboot", _ ) do
    Farmbot.Logger.log("Bot Going down for reboot in 5 seconds", [], ["BotControl"])
    spawn fn ->
      Farmbot.Logger.log("Rebooting!", [:ticker, :warning_toast], ["BotControl"])
      Process.sleep(5000)
      Farmbot.reboot
    end
    :ok
  end

  def handle_request("power_off", _ ) do
    Farmbot.Logger.log("Bot Going down in 5 seconds. Pls remeber me.",
      [:ticker, :warning_toast], ["BotControl"])
    spawn fn ->
      Farmbot.Logger.log("Powering Down!",
        [:ticker, :warning_toast], ["BotControl"])
      Process.sleep(5000)
      Nerves.Firmware.poweroff
    end
    :ok
  end

  def handle_request("mcu_config_update", [params]) when is_map(params) do
    case Enum.partition(params, fn({param, value}) ->
      param_int = Farmbot.Serial.Gcode.Parser.parse_param(param)
      spawn fn -> Command.update_param(param_int, value) end
    end)
    do
      {_, []} ->
        Farmbot.Logger.log("MCU params updated.", [:success_toast], ["RPCHANDLER"])
        # Farmbot.RPC.Handler.send_status
        :ok
      {_, failed} ->
        Farmbot.Logger.log("MCU params failed: #{inspect failed}", [:error_toast], ["RPCHANDLER"])
        # Farmbot.RPC.Handler.send_status
        :ok
    end
  end

  def handle_request("bot_config_update", [configs]) do
    case Enum.partition(configs, fn({config, value}) ->
      Farmbot.BotState.update_config(config, value)
    end) do
      {_, []} ->
        Farmbot.Logger.log("Bot Configs updated.", [:success_toast], ["RPCHANDLER"])
        # Farmbot.RPC.Handler.send_status
        :ok
      {_, failed} ->
        Farmbot.Logger.log("Bot Configs failed: #{inspect failed}", [:error_toast], ["RPCHANDLER"])
        # Farmbot.RPC.Handler.send_status
        :ok
    end
  end

  def handle_request("sync", _) do
    Farmbot.Sync.sync
    :ok
  end

  def handle_request("exec_sequence", [sequence]) do
    Map.drop(sequence, ["dirty"])
    |> Map.merge(%{"device_id" => -1, "id" => Map.get(sequence, "id") || -1})
    |> Sequence.create
    |> Farmbot.Scheduler.add_sequence
  end

  def handle_request("start_regimen", [%{"regimen_id" => id}]) when is_integer(id) do
    Farmbot.Sync.sync()
    regimen = Farmbot.Sync.get_regimen(id)
    Farmbot.Scheduler.add_regimen(regimen)
    :ok
  end

  def handle_request("start_regimen", params) do
    Logger.debug("bad params for start_regimen: #{inspect params}")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"regimen_id" => "number"})}
  end

  def handle_request("stop_regimen", [%{"regimen_id" => id}]) when is_integer(id) do
    regimen = Farmbot.Sync.get_regimen(id)
    running = GenServer.call(Farmbot.Scheduler, :state) |> Map.get(:regimens)

    {pid, ^regimen, _, _, _} = Farmbot.Scheduler.find_regimen(regimen, running)
    send(Farmbot.Scheduler, {:done, {:regimen, pid, regimen}})
    :ok
  end

  def handle_request("stop_regimen", params) do
    Logger.debug("bad params for stop_regimen: #{inspect params}")
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"regimen_id" => "number"})}
  end

  # Unhandled event. Probably not implemented if it got this far.
  def handle_request(event, params) do
    Logger.warn("[RPC_HANDLER] got valid rpc, but event is not implemented.")
    {:error, "Unhandled method", "#{inspect {event, params}}"}
  end

end
