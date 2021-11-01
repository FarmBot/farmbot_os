defmodule FarmbotOS.SysCalls.FactoryResetTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.SysCalls.FactoryReset

  setup :verify_on_exit!

  test "factory reset" do
    expect(FarmbotOS.System, :factory_reset, 1, fn reason, flag ->
      assert reason == "Soft resetting..."
      assert flag
      :ok
    end)
    assert :ok == FactoryReset.factory_reset("farmbot_os")
  end
end
