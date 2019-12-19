defmodule FarmbotCore.DeviceWorkerTest do
  use ExUnit.Case, async: false
  alias Farmbot.TestSupport.AssetFixtures
  alias FarmbotCore.Asset.Device
  alias FarmbotCore.AssetWorker
  alias Farmbot.TestSupport.CeleryScript.TestSysCalls

  describe "devices" do
    test "updates device triggering " do
      {:ok, _} = TestSysCalls.checkout()
      test_pid = self()
      params = %{needs_reset: true}
      assert %Device{} = dev = AssetFixtures.device(params)

      :ok =
        TestSysCalls.handle(TestSysCalls, fn
          kind, args ->
            send(test_pid, {kind, args})
            :ok
        end)

      {:ok, _pid} = AssetWorker.start_link(dev, [])
      assert_receive {:factory_reset, ["farmbot_os"]}
    end
  end
end
