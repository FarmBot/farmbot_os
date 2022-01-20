defmodule FarmbotOS.DeviceWorkerTest do
  use ExUnit.Case
  use Mimic

  alias Farmbot.TestSupport.AssetFixtures
  alias FarmbotOS.Asset.Device
  alias FarmbotOS.AssetWorker

  setup :set_mimic_global
  setup :verify_on_exit!

  def fresh_device(needs_reset \\ true) do
    params = %{needs_reset: needs_reset}
    assert %Device{} = dev = AssetFixtures.device_init(params)
    dev
  end

  test "initializes and runs noops" do
    dev = fresh_device(false)
    {:ok, _} = AssetWorker.start_link(dev, [])
    # Test noop functions:
    worker = FarmbotOS.AssetWorker.FarmbotOS.Asset.Device
    {:noreply, %{}} = worker.handle_info({:csvm_done, make_ref(), :ok}, %{})
    {:noreply, %{}} = worker.handle_cast({:new_data, %{}}, %{})
  end
end
