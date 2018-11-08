defmodule Farmbot.Firmware.GCODE do
  @moduledoc """
  Handles encoding and decoding of GCODEs.
  """

  alias Farmbot.Firmware.GCODE.{Decoder, Encoder}
  import Decoder, only: [do_decode: 2]
  import Encoder, only: [do_encode: 2]

  @typedoc "Tag is a binary integer. example: `\"123\"`"
  @type tag() :: nil | binary()

  @typedoc "Kind is an atom of the \"name\" of a command. Example: `:write_paramater`"
  @type kind() :: atom()

  @typedoc "Args is a list of args to a `kind`. example: `[x: 100.00]`"
  @type args() :: [arg]

  @typedoc "Example: `{:x, 100.00}` or `1` or `\"hello world\"`"
  @type arg() :: any()

  @doc """
  Takes a string representation of a GCODE, and returns a tuple representation of:
  `{tag, {kind, args}}`

  ## Examples
      iex(1)> Farmbot.Firmware.GCODE.decode("R00 Q100")
      {"100", {:report_idle, []}}
      iex(2)> Farmbot.Firmware.GCODE.decode("R00")
      {nil, {:report_idle, []}}
  """
  @spec decode(binary) :: {tag, {kind, args}}
  def decode(binary_with_q) when is_binary(binary_with_q) do
    code = String.split(binary_with_q, " ")
    {tag, [kind | args]} = extract_tag(code)
    {tag, do_decode(kind, args)}
  end

  @doc """
  Takes a tuple representation of a GCODE and returns a string.

  ## Examples
      iex(1)> Farmbot.Firmware.GCODE.encode({"444", {:report_idle, []}})
      "R00 Q444"
      iex(2)> Farmbot.Firmware.GCODE.encode({nil, {:report_idle, []}})
      "R00"
  """
  @spec encode({tag, {kind, args}}) :: binary()
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
