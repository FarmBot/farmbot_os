defmodule FarmbotOS.SysCalls.CheckUpdateTest do
  use ExUnit.Case, async: true
  # use Mimic
  # setup :verify_on_exit!

  test "in_progress?" do
    File.write!("temp1", "lol")
    assert FarmbotOS.UpdateSupport.in_progress?("temp1")
    File.rm!("temp1")
    refute FarmbotOS.UpdateSupport.in_progress?("temp1")
  end
end
