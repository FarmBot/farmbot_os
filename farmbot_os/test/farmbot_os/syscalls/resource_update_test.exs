defmodule FarmbotOS.SysCalls.ResourceUpdateTest do
  use ExUnit.Case

  alias FarmbotOS.SysCalls.ResourceUpdate

  test "resource_update/3 - Device" do
    params = %{name: "X is {{ x }}"}
    assert :ok == ResourceUpdate.resource_update("Device", 0, params)
    assert "X is -1" == FarmbotCore.Asset.device().name
  end
end
