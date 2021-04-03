defmodule FarmbotCore.Firmware.LineBuffer do
  @moduledoc """
  Serial character buffering doesn't always make sense. When
  reading serial input of line oriented data, you might not
  always capture a full line of text.
   * You might see only the end of a line.
   * You might get a complete line in two parts.
   * You might get garbled test because the device is not
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

  def new(string \\ "") do
    puts(%State{}, string)
  end

  def puts(state, string) do
    string
    |> IO.inspect(label: "BEFORE")
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
      clean_results =
        Enum.reduce(results, [], fn
          @wake_word, _ -> [@wake_word]
          item, list -> list ++ [item]
        end)

      {%{state | output: [], ready: true}, clean_results}
    else
      {%{state | output: []}, []}
    end
  end

  defp finalize(state, results) do
    {%{state | output: []}, results}
  end

  defp step(last_state, "\n") do
    next_output = last_state.output ++ ["#{last_state.buffer}\n"]
    %{last_state | output: next_output, buffer: []}
  end

  defp step(p, char), do: %{p | buffer: "#{p.buffer}#{char}"}
end
