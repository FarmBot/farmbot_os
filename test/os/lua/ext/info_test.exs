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

    {[coord], _lua} = Info.get_xyz([], lua)
    coordinate = FarmbotOS.Lua.Util.lua_to_elixir(coord)
    assert coordinate["x"] == 0
    assert coordinate["y"] == 0
    assert coordinate["z"] == 0
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

  test "utc()" do
    utc = DateTime.utc_now()
    now = String.slice(DateTime.to_string(utc), 0..15)
    lua_code = "return utc()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert String.starts_with?(actual, now)
  end

  test "utc(\"year\")" do
    year = DateTime.utc_now().year
    lua_code = "return utc(\"year\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == year
  end

  test "utc(\"month\")" do
    month = DateTime.utc_now().month
    lua_code = "return utc(\"month\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == month
  end

  test "utc(\"day\")" do
    day = DateTime.utc_now().day
    lua_code = "return utc(\"day\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == day
  end

  test "utc(\"minute\")" do
    minute = DateTime.utc_now().minute
    lua_code = "return utc(\"minute\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == minute
  end

  test "utc(\"second\")" do
    second = DateTime.utc_now().second
    lua_code = "return utc(\"second\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == second
  end

  test "local_time()" do
    tz = "America/Chicago"
    local = Timex.Timezone.convert(DateTime.utc_now(), tz)
    now = String.slice(DateTime.to_string(local), 0..15)
    lua_code = "return local_time()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert String.starts_with?(actual, now)
  end

  test "local_time(\"year\")" do
    tz = "America/Chicago"
    local = Timex.Timezone.convert(DateTime.utc_now(), tz)
    year = local.year
    lua_code = "return local_time(\"year\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == year
  end

  test "local_time(\"month\")" do
    tz = "America/Chicago"
    local = Timex.Timezone.convert(DateTime.utc_now(), tz)
    month = local.month
    lua_code = "return local_time(\"month\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == month
  end

  test "local_time(\"day\")" do
    tz = "America/Chicago"
    local = Timex.Timezone.convert(DateTime.utc_now(), tz)
    day = local.day
    lua_code = "return local_time(\"day\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == day
  end

  test "local_time(\"minute\")" do
    tz = "America/Chicago"
    local = Timex.Timezone.convert(DateTime.utc_now(), tz)
    minute = local.minute
    lua_code = "return local_time(\"minute\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == minute
  end

  test "local_time(\"second\")" do
    tz = "America/Chicago"
    local = Timex.Timezone.convert(DateTime.utc_now(), tz)
    second = local.second
    lua_code = "return local_time(\"second\")"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == second
  end

  test "current_year()" do
    year = DateTime.utc_now().year
    lua_code = "return current_year()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == year
  end

  test "current_month()" do
    month = DateTime.utc_now().month
    lua_code = "return current_month()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == month
  end

  test "current_day()" do
    day = DateTime.utc_now().day
    lua_code = "return current_day()"
    {:ok, [actual]} = lua(lua_code, lua_code)
    assert actual == day
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
