defmodule FarmbotOS.SystemTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.System
  alias FarmbotOS.Firmware.Command

  require Helpers
  setup :verify_on_exit!

  test "try_lock_fw - OK" do
    expect(Command, :lock, 1, fn -> :ok end)
    System.try_lock_fw()
  end

  test "try_lock_fw - NO" do
    Helpers.expect_log("Emergency lock failed. Powering down")
    expect(Command, :lock, 1, fn -> raise "BOOM" end)
    System.try_lock_fw()
  end
end
