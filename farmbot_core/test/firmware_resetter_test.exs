defmodule FarmbotCore.FirmwareResetterTest do
  require Helpers
  use ExUnit.Case
  alias FarmbotCore.FirmwareResetter
  use Mimic
  setup :verify_on_exit!

  test "find_reset_fun(nil)" do
    Helpers.expect_log("Using default reset function")
    {:ok, noop} = FirmwareResetter.find_reset_fun(nil)
    assert :ok == noop.()
  end
end
