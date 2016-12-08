defmodule Farmbot.RPC.Requests do
  @moduledoc """
    These are all callbacks from the Handler.
    Mostly forwards to the Command Module.
  """
  require Logger
  alias Nerves.Firmware
  alias Farmbot.Serial.Gcode.Parser, as: GcodeParser
  alias Farmbot.BotState
  alias Farmbot.Sync
  alias Sync.Database.Sequence
  alias Farmbot.Scheduler
  alias Farmbot.Logger, as: FarmbotLogger

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
  def handle_request("home_all", [%{"speed" => s}]) when is_integer s do
    spawn fn -> Command.home_all(s) end
    :ok
  end

  def handle_request("home_all", _params) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"speed" => "number"})}
  end

  # WRITE_PIN
  def handle_request("write_pin",
    [%{"pin_mode" => 1, "pin_number" => p, "pin_value" => v}])
    when is_integer(p) and
         is_integer(v)
  do
    spawn fn -> Command.write_pin(p,v,1) end
    :ok
  end

  def handle_request("write_pin",
    [%{"pin_mode" => 0, "pin_number" => p, "pin_value" => v}])
    when is_integer p and
         is_integer v
  do
    spawn fn -> Command.write_pin(p,v,0) end
    :ok
  end

  def handle_request("write_pin", _) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"pin_mode" => "1 or 2",
                       "pin_number" => "number", "pin_value" => "number"})}
  end

  def handle_request("toggle_pin",
    [%{"pin_number" => p}])
    when is_integer(p) do
    spawn fn -> Command.toggle_pin(p) end
    :ok
  end

  def handle_request("toggle_pin", _) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"pin_number" => "number"})}
  end

  # Move to a specific coord
  def handle_request("move_absolute",
    [%{"speed" => s, "x" => x, "y" => y, "z" => z}])
  when is_integer(x) and
       is_integer(y) and
       is_integer(z) and
       is_integer(s)
  do
    spawn fn -> Command.move_absolute(x,y,z,s) end
    :ok
  end

  def handle_request("move_absolute",  _params) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"x" => "number",
                       "y" => "number",
                       "z" => "number",
                       "speed" => "number"})}
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
    spawn fn ->
      Command.move_relative(
        %{x: x_move_by, y: y_move_by, z: z_move_by, speed: speed})
    end
    :ok
  end

  def handle_request("move_relative", _) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"x or y or z" => "number to move by",
                       "speed" => "number"})}
  end

  # Read status
  def handle_request("read_status", _) do
    Logger.debug ">> is reporting current status."
    GenEvent.call(BotState.EventManager,
                  Farmbot.RPC.Handler, :force_dispatch)
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

  def handle_request("reboot", _) do
    Logger.warn ">> is going down for reboot in 5 seconds!", channels: [:toast]
    spawn fn ->
      Process.sleep(5000)
      Farmbot.reboot
    end
    :ok
  end

  def handle_request("power_off", _) do
    Logger.debug ">> will power off in 5 seconds!", channels: [:toast]
    spawn fn ->
      Process.sleep(5000)
      Firmware.poweroff
    end
    :ok
  end

  def handle_request("mcu_config_update", [params]) when is_map(params) do
    params
    |> Enum.partition(
       fn({param, value}) ->
         param_int = GcodeParser.parse_param(param)
         spawn fn -> Command.update_param(param_int, value) end
       end)
    |> parse_mcu_config_output
    :ok
  end

  def handle_request("bot_config_update", [configs]) do
    case Enum.partition(configs, fn({config, value}) ->
      BotState.update_config(config, value)
    end) do
      {_, []} ->
        Logger.debug ">> has finished updating \
                      configuration.",
                      channels: [:toast]
        :ok
      {_, failed} ->
        Logger.error ">> encountered an error \
                      setting updating configuration: #{inspect failed}.",
                      channels: [:toast]
        :ok
    end
  end

  def handle_request("sync", _) do
    spawn fn ->
      Logger.debug ">> Is syncing."
      case Sync.sync do
        {:ok, _} -> Logger.debug ">> Is finished syncing."
        {:error, reason} ->
          Logger.debug(">> Had a problem syncing! #{inspect reason}")
      end
    end
    :ok
  end

  def handle_request("exec_sequence", [sequence]) do
    sequence
    |> Map.drop(["dirty"])
    |> Map.merge(%{"device_id" => -1, "id" => Map.get(sequence, "id") || -1})
    |> Sequence.validate!
    |> Scheduler.add_sequence
  end

  def handle_request("start_regimen",
    [%{"regimen_id" => id}]) when is_integer(id)
  do
    regimen = Sync.get_regimen(id)
    Scheduler.add_regimen(regimen)
    :ok
  end

  def handle_request("start_regimen", params) do
    Logger.error ">> could not start regimen: #{inspect params}"
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"regimen_id" => "number"})}
  end

  def handle_request("stop_regimen",
    [%{"regimen_id" => id}]) when is_integer(id)
  do
    regimen = Sync.get_regimen(id)
    running = Scheduler |> GenServer.call(:state) |> Map.get(:regimens)

    {pid, ^regimen, _, _, _} = Scheduler.find_regimen(regimen, running)
    send(Scheduler, {:done, {:regimen, pid, regimen}})
    :ok
  end

  def handle_request("stop_regimen", params) do
    Logger.error ">> could not stop regimen: #{inspect params}"
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"regimen_id" => "number"})}
  end

  def handle_request("calibrate", [%{"target" => thing}]) do
    spawn fn -> Command.calibrate(thing) end
    :ok
  end

  def handle_request("calibrate", _) do
    {:error, "BAD_PARAMS",
      Poison.encode!(%{"target" => "x | y | z"})}
  end

  def handle_request("dump_logs", _) do
    Logger.debug ">> is dumping logs. "
    spawn fn ->
      FarmbotLogger.dump
    end
    :ok
  end

  # Unhandled event. Probably not implemented if it got this far.
  def handle_request(event, params) do
    Logger.error ">> does not know how to \
                  handle: #{event} with params: #{inspect params}"
    {:error, "Unhandled method", "#{inspect {event, params}}"}
  end

  @spec parse_mcu_config_output({[any], [any]}) :: :ok
  defp parse_mcu_config_output({_, []}) do
    Logger.debug ">> has finished updating mcu paramaters.",
      channels: [:toast], type: :success
  end

  defp parse_mcu_config_output({_, failed}) do
    Logger.error ">> encountered an error \
                  setting mcu paramaters: #{inspect failed}.",
      channels: [:toast]
  end
end
