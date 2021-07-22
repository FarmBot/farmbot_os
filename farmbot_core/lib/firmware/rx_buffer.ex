defmodule FarmbotCore.Firmware.RxBuffer do
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
   * Normalize tokens by removing carraige returns, extra
     spaces, etc..
   * Ensure that buffer consumers only get complete lines of
     data and never a half finished line.
  """
  require Logger
  alias __MODULE__, as: State

  defstruct output: [], buffer: "", ready: false

  @new_line "\n"

  @doc ~S"""
  Create a new line buffer object.

  iex> new("r88 Q00\n")
  %FarmbotCore.Firmware.RxBuffer{
    buffer: "",
    output: [],
    ready: true
  }
  """
  def new(string \\ "") do
    puts(%State{}, string)
  end

  @doc ~S"""
  Create a new line buffer by appending to an existing buffer.

  iex> new("r88 Q00\n") |> puts("R99 ARDUINO STARTUP COMPLETE\n")
  %FarmbotCore.Firmware.RxBuffer{
    buffer: "",
    output: ["R99 ARDUINO STARTUP COMPLETE\n"],
    ready: true
  }
  """
  def puts(state, string) do
    %{state | output: [string], ready: true}
  end

  def puts_rc(state, string) do
    string
    |> String.upcase()
    |> String.replace(~r/\r*/, "")
    |> String.replace(~r/\r/, @new_line)
    |> String.replace(~r/\ +/, " ")
    |> String.replace(~r/\n+/, @new_line)
    |> String.split("")
    |> Enum.filter(fn
      "" -> false
      _ -> true
    end)
    |> Enum.reduce(state, fn
      @new_line, %{ready: false} ->
        %State{output: [], buffer: "", ready: true}

      _, %{ready: false} = state ->
        state

      char, state ->
        step(state, char)
    end)
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
      buffer: "R99 INCOMPLETE DATA",
      output: [],
      ready: true
    },
    ["R99 ARDUINO STARTUP COMPLETE"]
  }
  """
  def gets(state) do
    {%{state | output: []}, state.output}
  end

  def gets_rc(state) do
    results =
      state.output
      |> Enum.chunk_by(fn token -> token == @new_line end)
      |> Enum.map(fn chunk -> Enum.join(chunk, " ") end)
      |> Enum.join(" ")
      |> String.replace(~r/\n /, @new_line)
      |> String.split(~r/\n/)
      |> Enum.filter(fn
        # Valid GCode messages start with "R".
        # Throw away anything that doesn't.
        "R" <> _ -> true
        "" -> false
        s -> oh_no(s)
      end)

    finalize(state, results)
  end

  defp finalize(state, results) do
    {%{state | output: []}, results}
  end

  defp step(last_state, @new_line) do
    next_output = last_state.output ++ ["#{last_state.buffer}\n"]
    %{last_state | output: next_output, buffer: ""}
  end

  defp step(p, char), do: %{p | buffer: "#{p.buffer}#{char}"}

  @oh_no "===== DONT KNOW HOW TO HANDLE THIS: "
  defp oh_no(s) do
    Logger.debug(@oh_no <> inspect(s))
    false
  end
end
