defmodule FarmbotCore.DeviceWorkerTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Farmbot.TestSupport.AssetFixtures
  alias FarmbotCeleryScript.SysCalls.Stubs
  alias FarmbotCore.Asset.Device
  alias FarmbotCore.AssetWorker

  setup :set_mimic_global

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

    # Hmmm
    Process.sleep(300)
  end

  test "DO trigger factory reset during update" do
    dev = fresh_device(false)
    {:ok, pid} = AssetWorker.start_link(dev, [])

    expect(Stubs, :factory_reset, 1, fn _pkg ->
      :ok
    end)

    GenServer.cast(pid, {:new_data, %{dev | needs_reset: true}})
    Process.sleep(300)
  end

  test "DO NOT trigger factory reset during update" do
    dev = fresh_device(false)
    {:ok, _} = AssetWorker.start_link(dev, [])

    stub(Stubs, :factory_reset, fn _pkg ->
      nooo = "SHOULD NOT HAPPEN!"
      flunk(nooo)
      raise nooo
    end)

    Process.sleep(300)
  end
end
