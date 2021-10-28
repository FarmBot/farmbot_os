defmodule FarmbotCore.Firmware.ResetterTest do
  require Helpers
  use ExUnit.Case
  use Mimic

  alias FarmbotCore.Firmware.Resetter

  setup :verify_on_exit!

  test "find_reset_fun(nil)" do
    Helpers.expect_log("Using default reset function")
    {:ok, noop} = Resetter.find_reset_fun(nil)
    assert :ok == noop.()
  end

  defmodule GpioResetMock do
    def open(_pin, _mode), do: {:ok, :this_is_a_fake_gpio}
    def write(_gpio, _pin), do: :ok
    def close(_gpio), do: nil
  end

  test "run_special_reset" do
    Helpers.expect_logs([
      "Begin MCU reset",
      "Finish MCU Reset"
    ])

    assert :ok == Resetter.run_special_reset(GpioResetMock)
  end
end
