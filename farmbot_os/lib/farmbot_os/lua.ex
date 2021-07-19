defmodule FarmbotOS.Lua do
  @moduledoc """
  Embedded scripting language for "formulas" in the MOVE block,
  assertion, and general scripting via LUA block.
  """

  @type t() :: tuple()
  @type table() :: [{any, any}]
  require FarmbotCore.Logger
  require Logger

  alias FarmbotOS.Lua.Ext.{
    DataManipulation,
    Firmware,
    Info,
    Wait
  }

  # this function is used by SysCalls, but isn't a direct requirement.
  @doc "Logs an assertion based on it's result"
  def log_assertion(passed?, type, message) do
    meta = [assertion_passed: passed?, assertion_type: type]
    FarmbotCore.Logger.dispatch_log(__ENV__, :assertion, 2, message, meta)
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

    case eval(vm, lua_code) do
      {:ok, value} ->
        {:ok, value}

      {:error, {:lua_error, error, _lua}} ->
        {:error, "lua runtime error evaluating expression: #{inspect(error)}"}

      {:error, {:badmatch, {:error, [{line, :luerl_parse, parse_error}], _}}} ->
        FarmbotCore.Logger.error(
          1,
          """
          Failed to parse expression:
          `#{comment}.lua:#{line}`

          #{IO.iodata_to_binary(parse_error)}
          """,
          channels: [:toast]
        )

        {:error,
         "failed to parse expression (line:#{line}): #{
           IO.iodata_to_binary(parse_error)
         }"}

      {:error, error} ->
        {:error, error}

      error ->
        {:error, inspect(error)}
    end
  end

  @spec init() :: t()
  def init do
    :luerl.init()
    |> set_table([:check_position], &Firmware.check_position/2)
    |> set_table([:coordinate], &Firmware.coordinate/2)
    |> set_table([:current_hour], &Info.current_hour/2)
    |> set_table([:current_minute], &Info.current_minute/2)
    |> set_table([:current_month], &Info.current_month/2)
    |> set_table([:current_second], &Info.current_second/2)
    |> set_table([:emergency_lock], &Firmware.emergency_lock/2)
    |> set_table([:emergency_unlock], &Firmware.emergency_unlock/2)
    |> set_table([:env], &DataManipulation.env/2)
    |> set_table([:fbos_version], &Info.fbos_version/2)
    |> set_table([:find_axis_length], &Firmware.calibrate/2)
    |> set_table([:find_home], &Firmware.find_home/2)
    |> set_table([:firmware_version], &Info.firmware_version/2)
    |> set_table([:get_device], &DataManipulation.get_device/2)
    |> set_table([:get_fbos_config], &DataManipulation.get_fbos_config/2)
    |> set_table(
      [:get_firmware_config],
      &DataManipulation.get_firmware_config/2
    )
    |> set_table([:get_position], &Firmware.get_position/2)
    |> set_table([:go_to_home], &Firmware.go_to_home/2)
    |> set_table([:http], &DataManipulation.http/2)
    |> set_table([:inspect], &DataManipulation.json_encode/2)
    |> set_table([:json], [
      {:decode, &DataManipulation.json_decode/2},
      {:encode, &DataManipulation.json_encode/2}
    ])
    |> set_table([:move_absolute], &Firmware.move_absolute/2)
    |> set_table([:new_sensor_reading], &DataManipulation.new_sensor_reading/2)
    |> set_table([:read_pin], &Firmware.read_pin/2)
    |> set_table([:read_status], &Info.read_status/2)
    |> set_table([:send_message], &Info.send_message/2)
    |> set_table([:set_pin_io_mode], &Firmware.set_pin_io_mode/2)
    |> set_table([:soil_height], &DataManipulation.soil_height/2)
    |> set_table([:take_photo], &DataManipulation.take_photo/2)
    |> set_table([:uart], [
      {:open, &FarmbotCore.Firmware.LuaUART.open/2},
      {:list, &FarmbotCore.Firmware.LuaUART.list/2}
    ])
    |> set_table([:update_device], &DataManipulation.update_device/2)
    |> set_table([:update_fbos_config], &DataManipulation.update_fbos_config/2)
    |> set_table(
      [:update_firmware_config],
      &DataManipulation.update_firmware_config/2
    )
    |> set_table([:wait], &Wait.wait/2)
    |> set_table([:write_pin], &Firmware.write_pin/2)
  end

  @spec set_table(t(), Path.t(), any()) :: t()
  def set_table(lua, path, value) do
    :luerl.set_table(path, value, lua)
  end

  @spec eval(t(), String.t()) :: {:ok, any()} | {:error, any()}
  def eval(lua, hook) when is_binary(hook) do
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
end
