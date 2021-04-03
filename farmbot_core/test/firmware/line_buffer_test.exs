defmodule FarmbotCore.Firmware.LineBufferTest do
  use ExUnit.Case
  alias FarmbotCore.Firmware.LineBuffer
  doctest FarmbotCore.Firmware.LineBuffer, import: true

  @random_tokens ["", "\n", "\r", " ", "  ", "R88", "Y0.00", "R81", "XB1"]

  test "unexpected input" do
    random_text =
      1..1000
      |> Enum.to_list()
      |> Enum.map(fn _ -> Enum.random(@random_tokens) end)
      |> Enum.join("")
      |> IO.inspect(label: "=== DIRTY")

    {_, results} =
      random_text
      |> LineBuffer.new()
      |> LineBuffer.gets()

    Enum.map(results, fn chunk ->
      IO.inspect(chunk, label: "=======")

      refute String.at(chunk, 0) == "\r",
             "Starts with bad char #{inspect(chunk)}"

      refute chunk =~ "  ", "Contains double space #{inspect(chunk)}"

      refute String.at(chunk, 0) == "\n",
             "Starts with bad char #{inspect(chunk)}"

      refute chunk =~ "\n\n"
      refute chunk =~ "\r\r"
    end)
  end
end
