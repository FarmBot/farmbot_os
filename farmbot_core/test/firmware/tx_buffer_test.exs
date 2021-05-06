defmodule FarmbotCore.Firmware.TxBufferTest do
  use ExUnit.Case
  alias FarmbotCore.Firmware.TxBuffer
  doctest FarmbotCore.Firmware.TxBuffer, import: true

  def fake_buffer() do
    TxBuffer.new()
    |> TxBuffer.push({nil, "A"})
    |> TxBuffer.push({nil, "B"})
    |> TxBuffer.push({nil, "C"})
    |> TxBuffer.push({nil, "D"})
    |> TxBuffer.push({nil, "E"})
  end

  test "error_all/2 drains queue" do
    old_buffer = fake_buffer()

    next_state = TxBuffer.error_all(old_buffer, "Running unit tests")
    assert next_state

    assert next_state == TxBuffer.new()
  end

  test "process_next_message - Empty queue" do
    new = TxBuffer.new()
    result = TxBuffer.process_next_message(new, self())
    assert result == new
  end

  test "process_next_message - Waiting for response" do
    origin = %TxBuffer{
      autoinc: 0,
      current: %{
        id: 1,
        caller: nil,
        gcode: "E",
        echo: nil
        },
      queue: []
    }
    result = TxBuffer.process_next_message(origin, self())
    assert result == origin
  end
end
