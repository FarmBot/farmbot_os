defmodule FarmbotCore.Firmware.TxBufferTest do
  use ExUnit.Case
  alias FarmbotCore.Firmware.TxBuffer
  doctest FarmbotCore.Firmware.TxBuffer, import: true

  test "error_all/2 drains queue" do
    old_buffer =
      TxBuffer.new()
      |> TxBuffer.push({nil, "A"})
      |> TxBuffer.push({nil, "B"})
      |> TxBuffer.push({nil, "C"})
      |> TxBuffer.push({nil, "D"})
      |> TxBuffer.push({nil, "E"})

    old_state = %{tx_buffer: old_buffer}
    assert old_state
    next_state = TxBuffer.error_all(old_state, "Running unit tests")
    assert next_state
    # assert next_state == %{
    #   tx_buffer: %TxBuffer{ autoinc: 6, pending: %{}, queue: [] }
    # }
  end
end
