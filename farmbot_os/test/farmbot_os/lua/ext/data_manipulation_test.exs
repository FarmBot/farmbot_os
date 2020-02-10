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
end
