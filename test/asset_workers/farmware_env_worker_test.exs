defmodule FarmbotOS.FarmwareEnvAssetWorkerTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.{Asset.FarmwareEnv, BotState}
  @worker FarmbotOS.AssetWorker.FarmbotOS.Asset.FarmwareEnv

  describe "farmware env instance worker" do
    test "data updates" do
      expect(BotState, :set_user_env, 1, fn key, value ->
        assert key == "foo"
        assert value == "bar"
        :ok
      end)

      fake_env = %FarmwareEnv{key: "foo", value: "bar"}
      {:noreply, env, :hibernate} = @worker.handle_info(:timeout, fake_env)
      assert env == fake_env
    end
  end
end
