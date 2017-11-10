defmodule Farmbot.Firmware.Handler do
  @moduledoc """
  Any module that implements this behaviour should be a GenStage.

  The implementng stage should communicate with the various Farmbot
  hardware such as motors and encoders. The `Farmbot.Firmware` module
  will subscribe_to: the implementing handler. Events should be
  Gcodes as parsed by `Farmbot.Firmware.Gcode.Parser`.
  """

  @typedoc "Pid of a firmware implementation."
  @type handler :: pid

  @doc "Start a firmware handler."
  @callback start_link :: {:ok, handler}

  @typedoc false
  @type fw_ret_val :: :ok | {:error, term}

  @typedoc false
  @type vec3 :: Farmbot.Firmware.Vec3.t

  @typedoc false
  @type axis :: Farmbot.Firmware.Vec3.axis

  @typedoc false
  @type fw_param :: Farmbot.Firmware.Gcode.Param.t

  @typedoc "Speed of a command."
  @type speed :: number

  @typedoc "Pin"
  @type pin :: number

  @typedoc "Mode of a pin."
  @type pin_mode :: :digital | :analog

  @doc "Move to a position."
  @callback move_absolute(handler, vec3, speed) :: fw_ret_val

  @doc "Calibrate an axis."
  @callback calibrate(handler, axis, speed) :: fw_ret_val

  @doc "Find home on an axis."
  @callback find_home(handler, axis, speed) :: fw_ret_val

  @doc "Manually set an axis's current position to zero."
  @callback zero(handler, axis) :: fw_ret_val

  @doc "Home an axis."
  @callback home(handler, axis, speed) :: fw_ret_val

  @doc "Update a paramater."
  @callback update_param(handler, fw_param, number) :: fw_ret_val

  @doc "Read a paramater."
  @callback read_param(handler, fw_param) :: fw_ret_val

  @doc "Read all params"
  @callback read_all_params(handler) :: fw_ret_val

  @doc "Lock the firmware."
  @callback emergency_lock(handler) :: fw_ret_val

  @doc "Unlock the firmware."
  @callback emergency_unlock(handler) :: fw_ret_val

  @doc "Read a pin."
  @callback read_pin(handler, pin, pin_mode) :: fw_ret_val

  @doc "Write a pin."
  @callback write_pin(handler, pin, pin_mode, number) :: fw_ret_val

  @doc "Set a pin mode (input/output)"
  @callback set_pin_mode(handler, pin, :input | :output) :: fw_ret_val

  @doc "Request firmware version."
  @callback request_software_version(handler) :: fw_ret_val

end
