defmodule FarmbotOS.Lua do
  @moduledoc """
  Embedded scripting language for "formulas" in the MOVE block,
  assertion, and general scripting via LUA block.
  """

  @type t() :: tuple()
  @type table() :: [{any, any}]
  require FarmbotOS.Logger
  require Logger

  alias FarmbotOS.Lua.{
    DataManipulation,
    Firmware,
    Info,
    Wait
  }

  # this function is used by SysCalls, but isn't a direct requirement.
  @doc "Logs an assertion based on it's result"
  def log_assertion(passed?, type, message) do
    meta = [assertion_passed: passed?, assertion_type: type]
    FarmbotOS.Logger.dispatch_log(:assertion, 2, message, meta)
  end

  # HACK: Provide an implicit "return", since many users
  #       will want implicit returns. If we didn't do this,
  #       users would be forced to write `return` everywhere,
  #       even in the formula input seen in the MOVE block.
  def add_implicit_return(str) do
    # Don't add implicit return if:
    #   * Contains carraige return ("\n")
    #   * Contains assignment char ("=")
    #   * Contains `return` keyword
    has_return? = String.contains?(str, "return")
    has_assignment? = String.contains?(str, "=")
    has_cr? = String.contains?(str, "\n")
    properly_formed? = has_cr? || has_assignment? || has_return?

    if properly_formed? do
      str
    else
      "return (#{str})"
    end
  end

  @doc """
  `extra_vm_args` is a set of extra args to place inside the
  Lua sandbox. The extra args are passed to set_table/3
  """
  def perform_lua(lua_code, extra_vm_args, comment) do
    comment = comment || "sequence"
    lua_code = add_implicit_return(lua_code)
    reducer = fn args, vm -> apply(__MODULE__, :set_table, [vm | args]) end
    vm = Enum.reduce(extra_vm_args, init(), reducer)

    case raw_eval(vm, lua_code) do
      {:ok, value} ->
        {:ok, value}

      {:error, {:lua_error, error, _lua}} ->
        {:error, "lua runtime error evaluating expression: #{inspect(error)}"}

      {:error, {:badmatch, {:error, [{line, :luerl_parse, parse_error}], _}}} ->
        FarmbotOS.Logger.error(
          1,
          """
          Failed to parse expression:
          `#{comment}.lua:#{line}`

          #{IO.iodata_to_binary(parse_error)}
          """,
          channels: [:toast]
        )

        {:error,
         "failed to parse expression (line:#{line}): #{IO.iodata_to_binary(parse_error)}"}

      {:error, error, backtrace} ->
        IO.inspect(backtrace, label: "=== LUA ERROR TRACE")
        {:error, error}

      {:error, error} ->
        {:error, error}

      error ->
        {:error, inspect(error)}
    end
  end

  def init do
    # FarmbotOS.Lua.init()
    reducer = fn {k, v}, lua -> set_table(lua, [k], v) end
    Enum.reduce(builtins(), :luerl.init(), reducer)
  end

  def set_table(lua, path, value) do
    :luerl.set_table(path, value, lua)
  end

  def raw_eval(lua, hook) when is_binary(hook) do
    :luerl.eval(hook, lua)
  end

  def unquote(:do)(lua, hook) when is_binary(hook) do
    :luerl.do(hook, lua)
  catch
    :error, {:error, reason} ->
      {{:error, reason}, lua}

    error, reason ->
      {{:error, {error, reason}}, lua}
  end

  # Wrap a function so that it cannot be called when device
  # is locked.
  def safe(action, fun) when is_function(fun, 2) do
    fn args, lua ->
      if FarmbotOS.Firmware.UARTCoreSupport.locked?() do
        {[nil, "Can't #{action} when locked."], :luerl.stop(lua)}
      else
        fun.(args, lua)
      end
    end
  end

  def execute_script(name) do
    fn _, lua ->
      case FarmbotOS.SysCalls.Farmware.execute_script(name, %{}) do
        {:error, reason} -> {[reason], lua}
        :ok -> {[], lua}
        other -> {[inspect(other)], lua}
      end
    end
  end

  def builtins() do
    %{
      base64: [
        {:decode, &DataManipulation.b64_decode/2},
        {:encode, &DataManipulation.b64_encode/2}
      ],
      json: [
        {:decode, &DataManipulation.json_decode/2},
        {:encode, &DataManipulation.json_encode/2}
      ],
      uart: [
        {:open, &FarmbotOS.Firmware.LuaUART.open/2},
        {:list, &FarmbotOS.Firmware.LuaUART.list/2}
      ],
      auth_token: &Info.auth_token/2,
      check_position: &Firmware.check_position/2,
      coordinate: &Firmware.coordinate/2,
      current_hour: &Info.current_hour/2,
      current_minute: &Info.current_minute/2,
      current_month: &Info.current_month/2,
      current_second: &Info.current_second/2,
      emergency_lock: &Firmware.emergency_lock/2,
      emergency_unlock: &Firmware.emergency_unlock/2,
      env: &DataManipulation.env/2,
      fbos_version: &Info.fbos_version/2,
      find_axis_length: &Firmware.calibrate/2,
      find_home: safe("find home", &Firmware.find_home/2),
      firmware_version: &Info.firmware_version/2,
      get_device: &DataManipulation.get_device/2,
      get_fbos_config: &DataManipulation.get_fbos_config/2,
      get_firmware_config: &DataManipulation.get_firmware_config/2,
      get_position: &Firmware.get_position/2,
      go_to_home: safe("go to home", &Firmware.go_to_home/2),
      http: &DataManipulation.http/2,
      inspect: &DataManipulation.json_encode/2,
      move_absolute: safe("move device", &Firmware.move_absolute/2),
      new_sensor_reading: &DataManipulation.new_sensor_reading/2,
      read_pin: &Firmware.read_pin/2,
      read_status: &Info.read_status/2,
      send_message: &Info.send_message/2,
      set_pin_io_mode: &Firmware.set_pin_io_mode/2,
      soil_height: &DataManipulation.soil_height/2,
      take_photo_raw: &DataManipulation.take_photo_raw/2,
      take_photo: execute_script("take-photo"),
      calibrate_camera: execute_script("camera-calibration"),
      detect_plants: execute_script("plant-detection"),
      measure_soil_height: execute_script("Measure Soil Height"),
      update_device: &DataManipulation.update_device/2,
      update_fbos_config: &DataManipulation.update_fbos_config/2,
      update_firmware_config: &DataManipulation.update_firmware_config/2,
      wait: &Wait.wait/2,
      write_pin: safe("write pin", &Firmware.write_pin/2)
    }
  end
end
