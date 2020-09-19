defmodule FarmbotOS.UpdateSupportTest do
  use ExUnit.Case, async: true
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.UpdateSupport

  test "do_flash_firmware" do
    expect(System, :cmd, 1, fn path, args ->
      assert path == "fwup"

      assert args == [
               "-a",
               "-i",
               "/root/upgrade.fw",
               "-d",
               "/dev/mmcblk0",
               "-t",
               "upgrade"
             ]

      {:ok, 0}
    end)

    UpdateSupport.do_flash_firmware()
  end
end
