defmodule FarmbotOS.FirmwareConfigTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.FirmwareConfig, as: Config
  alias FarmbotOS.AssetWorker.FarmbotOS.Asset.FirmwareConfig, as: Worker
  @conf %Config{}
  test "init" do
    assert {:ok, @conf} == Worker.init(@conf)
  end
end
