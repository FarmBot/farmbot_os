defmodule FarmbotCore.DeviceWorkerTest do
  use ExUnit.Case
  use Mimic

  alias Farmbot.TestSupport.AssetFixtures
  alias FarmbotCeleryScript.SysCalls.Stubs
  alias FarmbotCore.Asset.Device
  alias FarmbotCore.AssetWorker

  setup :set_mimic_global
  setup :verify_on_exit!

  def fresh_device() do
    assert %Device{} = dev = AssetFixtures.device_init(%{})
    dev
  end

  test "DO NOT trigger factory reset during update" do
    dev = fresh_device()
    {:ok, _} = AssetWorker.start_link(dev, [])

    stub(Stubs, :factory_reset, fn _pkg ->
      nooo = "SHOULD NOT HAPPEN!"
      flunk(nooo)
      raise nooo
    end)
  end
end
