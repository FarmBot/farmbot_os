defmodule FarmbotOS.SysCalls.CheckUpdateTest do
  use ExUnit.Case, async: true
  # use Mimic
  # setup :verify_on_exit!
  alias FarmbotOS.SysCalls.CheckUpdate

  test "in_progress?" do
    File.write!("temp1", "lol")
    assert CheckUpdate.in_progress?("temp1")
    File.rm!("temp1")
    refute CheckUpdate.in_progress?("temp1")
  end
end
