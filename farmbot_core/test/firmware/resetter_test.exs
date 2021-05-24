defmodule FarmbotCore.Firmware.ResetterTest do
  require Helpers
  use ExUnit.Case
  alias FarmbotCore.Firmware.Resetter
  use Mimic
  setup :verify_on_exit!

  test "find_reset_fun(nil)" do
    Helpers.expect_log("Using default reset function")
    {:ok, noop} = Resetter.find_reset_fun(nil)
    assert :ok == noop.()
  end
end
