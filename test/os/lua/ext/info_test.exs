defmodule FarmbotOS.Lua.InfoTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.Celery.SysCallGlue
  setup :verify_on_exit!

  def lua(test_name, lua_code) do
    FarmbotOS.Lua.perform_lua(lua_code, [], test_name)
  end

  test "send_message() - no channel" do
    code = """
      send_message("info", "unit testing")
    """

    expect(SysCallGlue, :send_message, 1, fn kind, message, channels ->
      assert kind == "info"
      assert message == "unit testing"
      assert channels == []
      :ok
    end)

    assert {:ok, []} == lua("send_message()", code)
  end

  test "send_message() - with channel" do
    code = """
      send_message("info", "unit testing", "toast")
    """

    expect(SysCallGlue, :send_message, 1, fn kind, message, _ ->
      assert kind == "info"
      assert message == "unit testing"
      :ok
    end)

    assert {:ok, []} == lua("send_message() - with channel", code)
  end

  test "fbos_version()" do
    lua_code = "return fbos_version()"
    {:ok, [actual, nil]} = lua(lua_code, lua_code)
    assert actual == FarmbotOS.Project.version()
  end

  test "firmware_version()" do
    lua_code = "return firmware_version()"
    {:ok, [actual, nil]} = lua(lua_code, lua_code)
    assert actual == nil
  end

  test "auth_token()" do
    expect(FarmbotOS.Config, :get_config_value, 2, fn
      t, k, "token" ->
        assert t == :string
        assert k == "authorization"
        "fake_token"

      _, _, _ ->
        "+++++"
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
    assert_in_delta(actual, hour, 1, "hour value not correct")
  end

  test "current_minute()" do
    minute = DateTime.utc_now().minute
    lua_code = "return current_minute()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert_in_delta(actual, minute, 1, "minute value not correct")
  end

  test "current_second()" do
    second = DateTime.utc_now().second
    lua_code = "return current_second()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert_in_delta(actual, second, 6, "second value not correct")
  end
end
