defmodule FarmbotCore.Firmware.LineBufferTest do
  use ExUnit.Case
  alias FarmbotCore.Firmware.LineBuffer
  doctest FarmbotCore.Firmware.LineBuffer, import: true

  @random_tokens [
    "",
    "\n",
    "\r",
    " ",
    "  ",
    "R88",
    "Y0.00",
    "R81",
    "XB1",
    "r99",
    "Q0",
    "Q1",
    "R99 ARDUINO STARTUP COMPLETE\n"
  ]

  test "unexpected input" do
    random_text =
      1..1000
      |> Enum.to_list()
      |> Enum.map(fn _ -> Enum.random(@random_tokens) end)
      |> Enum.join("")

    {_, results} =
      random_text
      |> LineBuffer.new()
      |> LineBuffer.gets()

    Enum.map(results, fn chunk ->
      refute chunk =~ "\r", "Contains non-printing char #{inspect(chunk)}"
      refute chunk =~ "\n", "Contains non-printing char #{inspect(chunk)}"
      refute chunk =~ "  ", "Contains double space #{inspect(chunk)}"
    end)
  end
end
