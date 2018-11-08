defmodule Farmbot.Firmware.GCODE do
  @moduledoc """
  Handles encoding and decoding of GCODEs.
  """

  alias Farmbot.Firmware.GCODE.{Decoder, Encoder}
  import Decoder, only: [do_decode: 2]
  import Encoder, only: [do_encode: 2]

  @typedoc "Tag is a binary integer. example: `\"123\"`"
  @type tag() :: nil | binary()

  @typedoc "RXX codes. Reports information."
  @type report_kind ::
          :report_idle
          | :report_begin
          | :report_success
          | :report_error
          | :report_busy
          | :report_axis_state
          | :report_retry
          | :report_echo
          | :report_invalid
          | :report_home_complete
          | :report_position
          | :report_paramaters_complete
          | :report_paramater
          | :report_calibration_paramater
          | :report_status_value
          | :report_pin_value
          | :report_axis_timeout
          | :report_end_stops
          | :report_version
          | :report_encoders_scaled
          | :report_encoders_raw
          | :report_emergency_lock
          | :report_no_config
          | :report_debug_message

  @typedoc "Movement commands"
  @type command_kind ::
          :command_movement
          | :command_movement_home
          | :command_movement_find_home
          | :command_movement_calibrate

  @typedoc "Read/Write commands."
  @type read_write_kind ::
          :paramater_read_all
          | :paramater_read
          | :paramater_write
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

  @type emergency_commands :: :command_emergency_lock | :command_emergency_unlock

  @typedoc "Kind is an atom of the \"name\" of a command. Example: `:write_paramater`"
  @type kind() :: report_kind | command_kind | read_write_kind | :unknown

  @typedoc "Args is a list of args to a `kind`. example: `[x: 100.00]`"
  @type args() :: [arg]

  @typedoc "Example: `{:x, 100.00}` or `1` or `\"hello world\"`"
  @type arg() :: any()

  @typedoc "Constructed GCODE."
  @type t :: {tag(), {kind(), args}}

  def new(kind, args, tag \\ nil) do
    {tag, {kind, args}}
  end

  @doc """
  Takes a string representation of a GCODE, and returns a tuple representation of:
  `{tag, {kind, args}}`

  ## Examples
      iex(1)> Farmbot.Firmware.GCODE.decode("R00 Q100")
      {"100", {:report_idle, []}}
      iex(2)> Farmbot.Firmware.GCODE.decode("R00")
      {nil, {:report_idle, []}}
  """
  @spec decode(binary()) :: t()
  def decode(binary_with_q) when is_binary(binary_with_q) do
    code = String.split(binary_with_q, " ")

    case extract_tag(code) do
      {tag, [kind | args]} ->
        {tag, do_decode(kind, args)}

      {tag, []} ->
        {tag, {:unknown, []}}
    end
  end

  @doc """
  Takes a tuple representation of a GCODE and returns a string.

  ## Examples
      iex(1)> Farmbot.Firmware.GCODE.encode({"444", {:report_idle, []}})
      "R00 Q444"
      iex(2)> Farmbot.Firmware.GCODE.encode({nil, {:report_idle, []}})
      "R00"
  """
  @spec encode(t()) :: binary()
  def encode({nil, {kind, args}}) do
    do_encode(kind, args)
  end

  def encode({tag, {kind, args}}) do
    str = do_encode(kind, args)
    str <> " Q" <> tag
  end

  @doc false
  @spec extract_tag([binary()]) :: {tag(), [binary()]}
  def extract_tag(list) when is_list(list) do
    with {"Q" <> bin_tag, list} when is_list(list) <- List.pop_at(list, -1) do
      {bin_tag, list}
    else
      # if there was no Q code provided
      {_, data} when is_list(data) -> {nil, list}
    end
  end
end
