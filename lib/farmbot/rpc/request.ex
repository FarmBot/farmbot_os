defmodule Farmbot.RPC.Requests do

  @moduledoc """
    These are all callbacks from the Handler.
    Mostly forwards to the Command Module.
  """
  require Logger
  @spec handle_request(String.t, [map,...])
  :: :ok | {:error, Strint.t} | {:error, Strint.t, String.t}

  @doc """
      Handles parsed RPC requests. Must return :ok, or the request is considered
      an error and will not give a very helpful message.\n
      Example:
        iex> handle_request("emergency_lock", [])
        :ok
      Example:
        iex> handle_request("something", [])
        {:error, "Unhandled method", "{"somethign", []}" }
  """
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
    GenEvent.call(BotStateEventManager, Farmbot.RPC.Handler, :force_dispatch)
    # GenServer.cast(Farmbot.BotState.Monitor, :force_dispatch)
  end

  def handle_request("check_updates", _) do
    spawn fn ->
      Farmbot.Updates.Handler.check_and_download_updates(:os)
    end
    :ok
  end

  def handle_request("check_arduino_updates", _) do
    spawn fn ->
      Farmbot.Updates.Handler.check_and_download_updates(:fw)
    end
    :ok
  end

  def handle_request("reboot", _ ) do
    Logger.warn("Bot going down for reboot in 5 seconds!", type: :toast)
    spawn fn ->
      Logger.warn("REBOOTING!!!!!", type: :toast)
      Process.sleep(5000)
      Farmbot.reboot
    end
    :ok
  end

  def handle_request("power_off", _ ) do
    # Log something here("Bot Going down in 5 seconds. Pls remeber me.",
      # [:ticker, :warning_toast], ["BotControl"])
    spawn fn -> nil
      # Log something here("Powering Down!",
        # [:ticker, :warning_toast], ["BotControl"])
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
        # Log something here("MCU params updated.", [:success_toast], ["RPCHANDLER"])
        :ok
      {_, failed} ->
        # Log something here("MCU params failed: #{inspect failed}", [:error_toast], ["RPCHANDLER"])
        :ok
    end
  end

  def handle_request("bot_config_update", [configs]) do
    case Enum.partition(configs, fn({config, value}) ->
      Farmbot.BotState.update_config(config, value)
    end) do
      {_, []} ->
        # Log something here("Bot Configs updated.", [:success_toast], ["RPCHANDLER"])
        :ok
      {_, failed} ->
        # Log something here("Bot Configs failed: #{inspect failed}", [:error_toast], ["RPCHANDLER"])
        :ok
    end
  end

  def handle_request("sync", _) do
    spawn fn ->
      Farmbot.Sync.sync
      receive do
        {:sync_complete,_} -> :ok
        {:error, _reason} -> :fail
      end
    end
    :ok
  end

  def handle_request("exec_sequence", [sequence]) do
    Map.drop(sequence, ["dirty"])
    |> Map.merge(%{"device_id" => -1, "id" => Map.get(sequence, "id") || -1})
    |> Farmbot.Sync.Database.Sequence.validate!
    |> Farmbot.Scheduler.add_sequence
  end

  def handle_request("start_regimen", [%{"regimen_id" => id}]) when is_integer(id) do
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

  def handle_request("calibrate", [%{"target" => thing}]) do
    spawn fn -> Command.calibrate(thing) end
    :ok
  end

  def handle_request("calibrate", params) do
    Logger.error "Bad params for calibtrate: #{inspect params}"
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"target" => "x | y | z" })}
  end

  # Unhandled event. Probably not implemented if it got this far.
  def handle_request(event, params) do
    Logger.warn("[RPC_HANDLER] got valid rpc, but event is not implemented.")
    {:error, "Unhandled method", "#{inspect {event, params}}"}
  end

end
