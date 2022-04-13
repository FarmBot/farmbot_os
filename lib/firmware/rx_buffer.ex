defmodule FarmbotOS.Firmware.RxBuffer do
  @moduledoc """
  Serial character buffering doesn't always make sense. When
  reading serial input of line oriented data, you might not
  always capture a full line of text.
   * You might see only the end of a line.
   * You might get a complete line in two parts.
   * You might get garbled text because the device is not
     truly online yet.
   * If you are lucky, You might get the whole line in one part.

  Because serial data is not emitted in predictable sizes, and
  because the GCode spec is line based, we need an extra layer
  of safety to ensure we only get data that makes sense:

   * When parsing an incoming stream of new data, discard all
     data prior to the first @new_line. Data before the first
     @new_line is never complete and is potentially garbage.
   * Normalize tokens by removing carriage returns, extra
     spaces, etc..
   * Ensure that buffer consumers only get complete lines of
     data and never a half finished line.
  """
  require Logger
  alias __MODULE__, as: State

  defstruct output: [], buffer: "", ready: false

  @doc ~S"""
  Create a new line buffer object.

  iex> new("r88 Q00")
  %FarmbotOS.Firmware.RxBuffer{
    buffer: "",
    output: ["R88 Q00"],
    ready: true
  }
  """
  def new(string \\ "") do
    puts(%State{}, string)
  end

  @doc ~S"""
  Create a new line buffer by appending to an existing buffer.

  iex> new("r88 Q00\n") |> puts("R99 ARDUINO STARTUP COMPLETE\n")
  %FarmbotOS.Firmware.RxBuffer{
    buffer: "",
    output: ["R99 ARDUINO STARTUP COMPLETE\n"],
    ready: true
  }
  """
  def puts(state, string) do
    %{state | output: [String.upcase(string)], ready: true}
  end

  @doc ~S"""
  Harvest well-formed data from a line buffer. Returns a tuple
  containing a new line buffer at element 0 and an array of
  strings that are guaranteed to be properly buffered.

  iex> new("r88 Q00\n")
  ...>    |> puts("R99 ARDUINO STARTUP COMPLETE\n")
  ...>    |> puts("r99 InCoMpLeTe DaTA")
  ...>    |> gets()
  {
    %RxBuffer{
      buffer: "",
      output: [],
      ready: true
    },
    ["R99 INCOMPLETE DATA"]
  }
  """
  def gets(state) do
    {%{state | output: []}, state.output}
  end
end
