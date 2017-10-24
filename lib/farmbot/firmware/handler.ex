defmodule Farmbot.Firmware.Handler do
  @moduledoc """
  Any module that implements this behaviour should be a GenStage.

  The implementng stage should communicate with the various Farmbot
  hardware such as motors and encoders. The `Farmbot.Firmware` module
  will subscribe_to: the implementing handler. Events should be
  Gcodes as parsed by `Farmbot.Firmware.Gcode.Parser`.
  """

  @doc "Start a firmware handler."
  @callback start_link :: GenServer.on_start()

  @typedoc false
  @type fw_ret_val :: :ok | {:error, term}

  @typedoc false
  @type vec3 :: Farmbot.Firmware.Vec3.t

  @typedoc false
  @type axis :: Farmbot.Firmware.Vec3.axis

  @typedoc false
  @type fw_param :: Farmbot.Firmware.Gcode.Param.t

  @typedoc "Pin"
  @type pin :: number

  @typedoc "Mode of a pin."
  @type pin_mode :: :digital | :analog

  @doc "Move to a position."
  @callback move_absolute(vec3) :: fw_ret_val

  @doc "Calibrate an axis."
  @callback calibrate(axis) :: fw_ret_val

  @doc "Update a paramater."
  @callback update_param(fw_param, number) :: fw_ret_val

  @callback read_param(fw_param) :: {:ok, number} | {:error, term}

  @doc "Lock the firmware."
  @callback emergency_lock() :: fw_ret_val

  @doc "Unlock the firmware."
  @callback emergency_unlock() :: fw_ret_val

  @doc "Find home on an axis."
  @callback find_home(axis) :: fw_ret_val

  @doc "Read a pin."
  @callback read_pin(pin, pin_mode) :: {:ok, number} | {:error, term}

  @doc "Write a pin."
  @callback write_pin(pin, pin_mode, number) :: fw_ret_val
end
