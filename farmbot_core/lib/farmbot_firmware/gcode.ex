defmodule FarmbotFirmware.GCODE do
  @moduledoc """
  Handles encoding and decoding of GCODEs.
  """

  @typedoc "Tag is a binary integer. example: `\"123\"`"
  @type tag() :: nil | binary()

  @typedoc "RXX codes. Reports information."
  @type report_kind ::
          :report_axis_state
          | :report_axis_timeout
          | :report_begin
          | :report_busy
          | :report_calibration_parameter_value
          | :report_debug_message
          | :report_echo
          | :report_emergency_lock
          | :report_encoders_raw
          | :report_encoders_scaled
          | :report_end_stops
          | :report_error
          | :report_home_complete
          | :report_idle
          | :report_invalid
          | :report_load
          | :report_no_config
          | :report_parameter_value
          | :report_parameters_complete
          | :report_pin_value
          | :report_position
          | :report_position_change
          | :report_retry
          | :report_software_version
          | :report_status_value
          | :report_success

  @typedoc "Movement commands"
  @type command_kind ::
          :command_movement
          | :command_movement_home
          | :command_movement_find_home
          | :command_movement_calibrate

  @typedoc "Read/Write commands."
  @type read_write_kind ::
          :parameter_read_all
          | :parameter_read
          | :parameter_write
          | :status_read
          | :status_write
          | :pin_read
          | :pin_write
          | :pin_mode_write
          | :servo_write
          | :end_stops_read
          | :position_read
          | :software_version_read
          | :position_write_zero

  @type emergency_commands ::
          :command_emergency_lock | :command_emergency_unlock

  @typedoc "Kind is an atom of the \"name\" of a command. Example: `:write_parameter`"
  @type kind() :: report_kind | command_kind | read_write_kind | :unknown

  @typedoc "Args is a list of args to a `kind`. example: `[x: 100.00]`"
  @type args() :: [arg]

  @typedoc "Example: `{:x, 100.00}` or `1` or `\"hello world\"`"
  @type arg() :: any()

  @typedoc "Constructed GCODE."
  @type t :: {tag(), {kind(), args}}
end
