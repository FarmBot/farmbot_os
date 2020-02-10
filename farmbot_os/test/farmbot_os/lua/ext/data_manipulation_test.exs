defmodule FarmbotOS.FarmbotOS.Lua.Ext.DataManipulationTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  def lua(test_name, lua_code) do
    FarmbotOS.Lua.eval_assertion(test_name, lua_code)
  end

  test "update_device()" do
    expect(FarmbotCore.Asset, :update_device!, 1, fn params ->
      assert %{"name" => "Test Farmbot"} == params
    end)

    lua_code = """
    update_device({name = "Test Farmbot"})
    return true
    """

    assert true == lua("update device test", lua_code)
  end

  test "get_device/0" do
    fake_device = %{fake: :device}
    expect(FarmbotCore.Asset, :device, 1, fn -> fake_device end)
    expect(FarmbotCore.Asset.Device, :render, 1, fn dev -> dev end)

    lua_code = """
    get_device()
    return true
    """

    assert true == lua("get device test", lua_code)
  end

  test "get_device/1" do
    fake_device = %{name: "my farmbot", id: 23}
    expect(FarmbotCore.Asset, :device, 1, fn -> fake_device end)
    expect(FarmbotCore.Asset.Device, :render, 1, fn dev -> dev end)

    lua_code = """
    return get_device("id") == 23
    """

    assert true == lua("get device test", lua_code)
  end
end
