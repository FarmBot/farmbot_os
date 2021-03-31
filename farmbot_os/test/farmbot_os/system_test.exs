defmodule FarmbotOS.SystemTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.System
  import ExUnit.CaptureLog
  setup :verify_on_exit!

  test "try_lock_fw - FW Genserver offline" do
    boom = fn -> System.try_lock_fw(StubFirmwareBad) end
    assert capture_log(boom) =~ "Emergency lock failed. Powering down (1)"
  end

  test "try_lock_fw - runtime error" do
    # Send `self()` since that will cause a runtime error
    # (expects module, not PID)
    boom = fn -> System.try_lock_fw(self()) end
    assert capture_log(boom) =~ "Emergency lock failed. Powering down (2)"
  end
end
