defmodule FarmbotOS.PinBindingWorkerTest do
  use ExUnit.Case
  use Mimic

  setup :set_mimic_global
  setup :verify_on_exit!

  alias FarmbotOS.AssetWorker.FarmbotOS.Asset.PinBinding

  test "triggering of a reboot from a pin binding" do
    params = %{
      pin_binding: %FarmbotOS.Asset.PinBinding{
        special_action: "reboot",
        pin_num: 0
      }
    }

    expect(FarmbotOS.Celery.SysCallGlue, :reboot, fn -> :ok end)
    PinBinding.handle_cast(:trigger, params)
  end

  test "triggering of a sync from a pin binding" do
    params = %{
      pin_binding: %FarmbotOS.Asset.PinBinding{
        special_action: "sync",
        pin_num: 0
      }
    }

    expect(FarmbotOS.Celery.SysCallGlue, :sync, fn -> :ok end)
    PinBinding.handle_cast(:trigger, params)
  end
end
