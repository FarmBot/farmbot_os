defmodule FarmbotOS.SystemTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.System
  alias FarmbotCore.Firmware.Command

  import ExUnit.CaptureLog
  setup :verify_on_exit!

  test "try_lock_fw - OK" do
    expect(Command, :lock, 1, fn -> :ok end)
    System.try_lock_fw()
  end

  test "try_lock_fw - NO" do
    expect(Command, :lock, 1, fn -> raise "BOOM" end)
    boom = fn -> System.try_lock_fw() end
    assert capture_log(boom) =~ "Emergency lock failed. Powering down"
  end
end
