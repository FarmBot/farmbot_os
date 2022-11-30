defmodule FarmbotOS.Lua.InfoTest do
  alias FarmbotOS.Lua.Info
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

  test "debug()" do
    lua = "return"
    msg = "message"

    expect(SysCallGlue, :send_message, 1, fn
      "debug", "message", [] -> :ok
    end)

    assert {[true, nil], lua} == Info.debug([msg], lua)
  end

  test "toast()" do
    lua = "return"
    msg = "message"

    expect(SysCallGlue, :send_message, 3, fn
      "info", "message", [:toast] -> :ok
      "fun", "message", [:toast] -> :ok
      "error", "message", [:toast] -> {:error, "error"}
    end)

    assert {[true, nil], lua} == Info.toast([msg], lua)
    assert {[true, nil], lua} == Info.toast([msg, "fun"], lua)
    assert {[nil, "error"], lua} == Info.toast([msg, "error"], lua)
  end

  test "read_status()" do
    lua = "return"
    expect(FarmbotOS.BotState, :fetch, 3, fn -> :ok end)

    expect(FarmbotOS.BotStateNG, :view, 3, fn _ ->
      %{location_data: %{position: %{x: 0}}}
    end)

    assert {[[{"location_data", [{"position", [{"x", 0}]}]}]], lua} ==
             Info.read_status([], lua)

    assert {[[{"x", 0}]], lua} ==
             Info.read_status(["location_data", "position"], lua)

    assert {[0], lua} ==
             Info.read_status(["location_data", "position", "x"], lua)
  end

  test "get_xyz()" do
    lua = "return"
    expect(FarmbotOS.BotState, :fetch, 1, fn -> :ok end)

    expect(FarmbotOS.BotStateNG, :view, 1, fn _ ->
      %{location_data: %{position: %{x: 0, y: 0, z: 0}}}
    end)

    assert {[[{"x", 0}, {"y", 0}, {"z", 0}]], lua} == Info.get_xyz([], lua)
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
