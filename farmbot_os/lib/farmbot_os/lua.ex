defmodule FarmbotOS.Lua do
  @moduledoc """
  Embedded scripting language for "formulas" in the MOVE block,
  assertion, and general scripting via LUA block.
  """

  @type t() :: tuple()
  @type table() :: [{any, any}]
  require FarmbotCore.Logger

  alias FarmbotOS.Lua.Ext.{
    DataManipulation,
    Firmware,
    Info
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
    if String.contains?(str, "return") do
      str
    else
      "return (#{str})"
    end
  end

  @doc """
  `eval_lua` evaluates Lua code. It is a more generalized
  version of `eval_assertion`.
  """
  def raw_lua_eval(str) when is_binary(str) do
    raw_lua_eval(str, [])
  end

  @doc """
  `extra_vm_args` is a set of extra args to place inside the
  Lua sandbox. The extra args are passed to set_table/3
  """
  def raw_lua_eval(str, extra_vm_args) do
    lua_code = add_implicit_return(str)
    reducer = fn args, vm ->
      raise "======= Stopped here ====="
      apply(__MODULE__, :set_table, [vm | args])
    end
    vm = Enum.reduce(extra_vm_args, init(), reducer)
    eval(vm, lua_code)
  end

  @doc """
  Evaluates some Lua code. The code should
  return a boolean value.
  """
  def eval_assertion(comment, str) when is_binary(str) do
    case raw_lua_eval(str) do
      {:ok, [true | _]} ->
        true

      {:ok, [false | _]} ->
        false

      {:ok, [_, reason]} when is_binary(reason) ->
        {:error, reason}

      {:ok, _data} ->
        {:error, "bad return value from expression evaluation"}

      {:error, {:lua_error, _error, _lua}} ->
        {:error, "lua runtime error evaluating expression"}

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

      error ->
        error
    end
  end

  @spec init() :: t()
  def init do
    :luerl.init()
    |> set_table([:calibrate], &Firmware.calibrate/2)
    |> set_table([:emergency_lock], &Firmware.emergency_lock/2)
    |> set_table([:emergency_unlock], &Firmware.emergency_unlock/2)
    |> set_table([:find_home], &Firmware.find_home/2)
    |> set_table([:home], &Firmware.home/2)
    |> set_table([:move_absolute], &Firmware.move_absolute/2)
    |> set_table([:get_position], &Firmware.get_position/2)
    |> set_table([:check_position], &Firmware.check_position/2)
    |> set_table([:get_pin], &Firmware.get_pin/2)
    |> set_table([:get_pins], &Firmware.get_pins/2)
    |> set_table([:coordinate], &Firmware.coordinate/2)
    |> set_table([:read_status], &Info.read_status/2)
    |> set_table([:send_message], &Info.send_message/2)
    |> set_table([:version], &Info.version/2)
    |> set_table([:current_month], &Info.current_month/2)
    |> set_table([:current_hour], &Info.current_hour/2)
    |> set_table([:current_minute], &Info.current_minute/2)
    |> set_table([:current_second], &Info.current_second/2)
    |> set_table([:update_device], &DataManipulation.update_device/2)
    |> set_table([:get_device], &DataManipulation.get_device/2)
    |> set_table([:update_fbos_config], &DataManipulation.update_fbos_config/2)
    |> set_table([:get_fbos_config], &DataManipulation.get_fbos_config/2)
    |> set_table(
      [:update_firmware_config],
      &DataManipulation.update_firmware_config/2
    )
    |> set_table(
      [:get_firmware_config],
      &DataManipulation.get_firmware_config/2
    )
    |> set_table([:new_farmware_env], &DataManipulation.new_farmware_env/2)
    |> set_table([:new_sensor_reading], &DataManipulation.new_sensor_reading/2)
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
