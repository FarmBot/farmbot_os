defmodule FarmbotOS.Lua.WaitTest do
  alias FarmbotOS.Lua.Wait
  alias FarmbotOS.Celery.SysCallGlue

  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  test "wait/2 - illegal value" do
    err_msg = "Do not use sleep for longer than three minutes."

    expect(SysCallGlue, :emergency_lock, 1, fn -> :ok end)

    expect(SysCallGlue, :send_message, 1, fn kind, msg, chans ->
      assert kind == "error"
      assert msg == err_msg
      assert chans == ["toast"]
      :ok
    end)

    assert {[], :example} == Wait.wait([180_010.0], :example)
  end

  test "wait/2 - legal value" do
    assert {[1], :example} == Wait.wait([1.23], :example)
  end
end
