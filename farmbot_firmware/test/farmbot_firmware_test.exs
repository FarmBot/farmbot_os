defmodule FarmbotFirmwareTest do
  use ExUnit.Case
  doctest FarmbotFirmware

  test "initialization (WIP)" do
    pid =
      start_supervised!({
        FarmbotFirmware,
        transport: FarmbotFirmware.StubTransport,
        side_effects: FarmbotCore.FirmwareSideEffects
      })

    # WIP
    assert is_pid(pid)
  end
end
