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
     data prior to the first @wake_word. Data before the first
     @wake_word is never complete and is potentially garbage.
   * Normalize tokens by removing carraige returns, extra
     spaces, etc..
   * Ensure that buffer consumers only get complete lines of
     data and never a half finished line.
  """

  alias __MODULE__, as: State

  defstruct output: [], buffer: "", ready: false

  @new_line "\n"
  @wake_word "R99 ARDUINO STARTUP COMPLETE"

  @doc ~S"""
  Create a new line buffer object.

  iex> new("r88 Q00\n")
  %FarmbotCore.Firmware.RxBuffer{
    buffer: "",
    output: ["R88 Q00\n"],
    ready: false
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
    output: ["R88 Q00\n", "R99 ARDUINO STARTUP COMPLETE\n"],
    ready: false
  }
  """
  def puts(state, string) do
    string
    |> String.upcase()
    |> String.replace(~r/\ +/, " ")
    |> String.replace(~r/\r/, "\n")
    |> String.replace(~r/\n+/, "\n")
    |> String.split("")
    |> Enum.filter(fn
      "" -> false
      _ -> true
    end)
    |> Enum.reduce(state, fn char, state -> step(state, char) end)
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
    results =
      state.output
      |> Enum.chunk_by(fn token -> token == @new_line end)
      |> Enum.map(fn chunk -> Enum.join(chunk, " ") end)
      |> Enum.join(" ")
      |> String.replace(~r/\n /, "\n")
      |> String.split(~r/\n/)
      |> Enum.filter(fn
        "" -> false
        _ -> true
      end)

    finalize(state, results)
  end

  defp finalize(%{ready: false} = state, results) do
    if Enum.member?(results, @wake_word) do
      clean = Enum.drop_while(results, fn w -> w != @wake_word end)
      {%{state | output: [], ready: true}, clean}
    else
      {%{state | output: []}, []}
    end
  end

  defp finalize(state, results) do
    {%{state | output: []}, results}
  end

  defp step(last_state, "\n") do
    next_output = last_state.output ++ ["#{last_state.buffer}\n"]
    %{last_state | output: next_output, buffer: ""}
  end

  defp step(p, char), do: %{p | buffer: "#{p.buffer}#{char}"}
end
