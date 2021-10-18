defmodule FarmbotOS.Lua.InfoTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  def lua(test_name, lua_code) do
    FarmbotOS.Lua.perform_lua(lua_code, [], test_name)
  end

  test "auth_token()" do
    expect(FarmbotCore.Config, :get_config_value, 1, fn t, k, v ->
      assert t == :string
      assert k == "authorization"
      assert v == "token"
      "fake_token"
    end)

    lua_code = "return auth_token()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == "fake_token"
  end

  test "current_month()" do
    month = DateTime.utc_now().month
    lua_code = "return current_month()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == month
  end

  test "current_hour()" do
    hour = DateTime.utc_now().hour
    lua_code = "return current_hour()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert_in_delta(actual, hour, 1, "hour value not corrrect")
  end

  test "current_minute()" do
    minute = DateTime.utc_now().minute
    lua_code = "return current_minute()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert_in_delta(actual, minute, 1, "minute value not corrrect")
  end

  test "current_second()" do
    second = DateTime.utc_now().second
    lua_code = "return current_second()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert_in_delta(actual, second, 6, "second value not corrrect")
  end
end
