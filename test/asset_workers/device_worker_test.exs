defmodule FarmbotCore.DeviceWorkerTest do
  use ExUnit.Case
  use Mimic

  alias Farmbot.TestSupport.AssetFixtures
  alias FarmbotCore.Celery.SysCallGlue.Stubs
  alias FarmbotCore.Asset.Device
  alias FarmbotCore.AssetWorker

  @im_so_sorry 300

  setup :set_mimic_global
  setup :verify_on_exit!

  def fresh_device(needs_reset \\ true) do
    params = %{needs_reset: needs_reset}
    assert %Device{} = dev = AssetFixtures.device_init(params)
    dev
  end

  test "triggering of factory reset during init" do
    expect(Stubs, :factory_reset, fn _ ->
      :ok
    end)

    dev = fresh_device()
    {:ok, _pid} = AssetWorker.start_link(dev, [])
    Process.sleep(@im_so_sorry)
  end

  test "DO trigger factory reset during update" do
    dev = fresh_device(false)
    {:ok, pid} = AssetWorker.start_link(dev, [])

    expect(Stubs, :factory_reset, 1, fn _pkg ->
      :ok
    end)

    GenServer.cast(pid, {:new_data, %{dev | needs_reset: true}})
    Process.sleep(@im_so_sorry)
  end

  test "DO NOT trigger factory reset during update" do
    dev = fresh_device(false)
    {:ok, _} = AssetWorker.start_link(dev, [])

    stub(Stubs, :factory_reset, fn _pkg ->
      nooo = "SHOULD NOT HAPPEN!"
      flunk(nooo)
      raise nooo
    end)
  end
end
