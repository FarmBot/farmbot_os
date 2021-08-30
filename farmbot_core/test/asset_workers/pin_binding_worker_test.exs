defmodule FarmbotCore.PinBindingWorkerTest do
  use ExUnit.Case
  use Mimic

  setup :set_mimic_global
  setup :verify_on_exit!

  alias FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding

  test "triggering of a reboot from a pin binding" do
    params = %{pin_binding: %{special_action: "reboot", pin_num: 0}}
    expect(FarmbotCeleryScript.SysCalls, :reboot, fn -> :ok end)
    PinBinding.handle_cast(:trigger, params)
  end

  test "triggering of a sync from a pin binding" do
    params = %{pin_binding: %{special_action: "sync", pin_num: 0}}
    expect(FarmbotCeleryScript.SysCalls, :sync, fn -> :ok end)
    PinBinding.handle_cast(:trigger, params)
  end
end
