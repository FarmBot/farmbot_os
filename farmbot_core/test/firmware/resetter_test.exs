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

  # test "express_k10 in non-express environments" do
  #   Helpers.expect_log("Using special express reset function")
  #   {:ok, noop} = Resetter.find_reset_fun("express_k10")
  #   assert :ok == noop.()
  # end
end
