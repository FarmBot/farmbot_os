defmodule FarmbotOS.Lua.DataManipulationTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.ResourceUpdate
  alias FarmbotOS.Lua.DataManipulation

  # Random tidbits needed for mocks / stubs.
  defstruct [:key, :value]

  def lua(test_name, lua_code) do
    FarmbotOS.Lua.perform_lua(lua_code, [], test_name)
  end

  test "take_photo_raw() - 0 return code" do
    expect(System, :cmd, 1, fn cmd, args ->
      assert cmd == "fswebcam"

      assert args == [
               "-r",
               "800x800",
               "-S",
               "10",
               "--no-banner",
               "--log",
               "/dev/null",
               "--save",
               "-"
             ]

      {"fake photo data", 0}
    end)

    name = "take_photo_raw() OK"
    code = "return take_photo_raw()"
    {:ok, [result, error]} = lua(name, code)
    assert result == "fake photo data"
    assert error == nil
  end

  test "take_photo_raw() - non 0 return code" do
    expect(System, :cmd, 1, fn cmd, args ->
      assert cmd == "fswebcam"

      assert args == [
               "-r",
               "800x800",
               "-S",
               "10",
               "--no-banner",
               "--log",
               "/dev/null",
               "--save",
               "-"
             ]

      {"error", 1}
    end)

    name = "take_photo_raw() OK"
    code = "return take_photo_raw()"
    {:ok, [result, error]} = lua(name, code)
    assert result == nil
    assert error == "error"
  end

  test "base64.decode()" do
    ascii_text = "Hello, world!"
    b64_text = "SGVsbG8sIHdvcmxkIQ=="
    lua_decode = "return base64.decode(#{inspect(b64_text)})"
    {:ok, [actual]} = lua(lua_decode, lua_decode)
    assert actual == ascii_text
  end

  test "base64.encode()" do
    ascii_text = "Hello, world!"
    b64_text = "SGVsbG8sIHdvcmxkIQ=="
    lua_encode = "base64.encode(#{inspect(ascii_text)})"
    {:ok, [encode_result]} = lua(lua_encode, lua_encode)
    assert encode_result == b64_text
  end

  test "update_firmware_config([table], lua)" do
    expect(FarmbotOS.Asset, :update_firmware_config!, 1, fn resource ->
      assert Map.fetch!(resource, "movement_axis_stealth_x") == 1.0
      resource
    end)

    expect(FarmbotOS.Asset.Private, :mark_dirty!, 1, fn resource, opts ->
      assert Map.fetch!(resource, "movement_axis_stealth_x") == 1.0
      assert opts == %{}
      resource
    end)

    lua_code = """
    return update_firmware_config({movement_axis_stealth_x = 1.0})
    """

    assert {:ok, [true]} == lua("update_firmware_config", lua_code)
  end

  test "soil_height" do
    expect(FarmbotOS.Celery.SpecialValue, :soil_height, 1, fn params ->
      assert params.x == 9.9
      assert params.y == 8.8
      5.55
    end)

    result = DataManipulation.soil_height([9.9, 8.8], :fake_lua)
    assert result == {[5.55], :fake_lua}
  end

  test "update_device()" do
    expect(ResourceUpdate, :update_resource, 1, fn "Device", nil, params ->
      assert %{"name" => "Test Farmbot"} == params
    end)

    lua_code = """
    update_device({name = "Test Farmbot"})
    return true
    """

    assert {:ok, [true]} == lua("update device test", lua_code)
  end

  test "garden_size/0" do
    expect(FarmbotOS.BotState, :fetch, 2, fn ->
      %{
        informational_settings: %{
          locked: false,
          locked_at: 0
        },
        mcu_params: %{
          movement_axis_nr_steps_y: 2.3,
          movement_step_per_mm_y: 4.5,
          movement_axis_nr_steps_x: 6.7,
          movement_step_per_mm_x: 8.9
        }
      }
    end)

    expected = [[{"x", 0.7528089887640449}, {"y", 0.5111111111111111}]]
    assert {:ok, expected} == lua("get garden size", "return garden_size()")
  end

  test "get_device/0" do
    fake_device = %{fake: :device}
    expect(FarmbotOS.Asset, :device, 1, fn -> fake_device end)
    expect(FarmbotOS.Asset.Device, :render, 1, fn dev -> dev end)

    lua_code = """
    get_device()
    return true
    """

    assert {:ok, [true]} == lua("get device test", lua_code)
  end

  test "get_device/1" do
    fake_device = %{name: "my farmbot", id: 23}
    expect(FarmbotOS.Asset, :device, 1, fn -> fake_device end)
    expect(FarmbotOS.Asset.Device, :render, 1, fn dev -> dev end)

    lua_code = """
    return get_device("id") == 23
    """

    assert {:ok, [true]} == lua("get device test/1", lua_code)
  end

  test "get_fbos_config/1" do
    fake_config = %{id: 47}
    expect(FarmbotOS.Asset, :fbos_config, 1, fn -> fake_config end)
    expect(FarmbotOS.Asset.FbosConfig, :render, 1, fn params -> params end)

    lua_code = "return 47 == get_fbos_config(\"id\")"

    assert {:ok, [true]} == lua("get_fbos_config", lua_code)
  end

  test "get_fbos_config/0" do
    fake_config = %{id: 47, foo: "bar"}
    expect(FarmbotOS.Asset, :fbos_config, 1, fn -> fake_config end)
    expect(FarmbotOS.Asset.FbosConfig, :render, 1, fn params -> params end)

    lua_code = """
    c = get_fbos_config()
    return (c.id == 47) and (c.foo == "bar")
    """

    assert {:ok, [true]} == lua("get_fbos_config/1", lua_code)
  end

  test "get_firmware_config/1" do
    fake_config = %{id: 47}
    expect(FarmbotOS.Asset, :firmware_config, 1, fn -> fake_config end)

    expect(FarmbotOS.Asset.FirmwareConfig, :render, 1, fn params -> params end)

    lua_code = "return 47 == get_firmware_config(\"id\")"

    assert {:ok, [true]} == lua("get_firmware_config", lua_code)
  end

  test "get_firmware_config/0" do
    fake_config = %{id: 47, foo: "bar"}
    expect(FarmbotOS.Asset, :firmware_config, 1, fn -> fake_config end)

    expect(FarmbotOS.Asset.FirmwareConfig, :render, 1, fn params -> params end)

    lua_code = """
    c = get_firmware_config()
    return (c.id == 47) and (c.foo == "bar")
    """

    assert {:ok, [true]} == lua("get_firmware_config/1", lua_code)
  end

  test "new_sensor_reading" do
    expect(FarmbotOS.Asset, :new_sensor_reading!, 1, fn params ->
      expected = %{
        "mode" => 1,
        "pin" => 0,
        "value" => 2,
        "x" => 3.0,
        "y" => 4.0,
        "z" => 5.0
      }

      assert expected == params
    end)

    lua_code = """
    return new_sensor_reading({
      mode = 1.1,
      pin = 0.1,
      value = 2.1,
      x = 3.0,
      y = 4.0,
      z = 5.0,
    })
    """

    assert {:ok, [true]} == lua("new_sensor_reading/1", lua_code)
  end

  test "take_photo - OK" do
    mock = fn "take-photo", %{} -> :ok end
    expect(FarmbotOS.SysCalls.Farmware, :execute_script, mock)
    fun = FarmbotOS.Lua.execute_script("take-photo")
    actual = fun.(:none, :lua)
    assert {[], :lua} == actual
  end

  test "take_photo - 'normal' errors" do
    mock = fn "take-photo", %{} -> {:error, "whatever"} end
    expect(FarmbotOS.SysCalls.Farmware, :execute_script, mock)
    fun = FarmbotOS.Lua.execute_script("take-photo")
    actual = fun.(:none, :lua)
    assert {["whatever"], :lua} == actual
  end

  test "take_photo - malformed errors" do
    mock = fn "take-photo", %{} -> {:something_else, "whoops"} end
    expect(FarmbotOS.SysCalls.Farmware, :execute_script, mock)
    fun = FarmbotOS.Lua.execute_script("take-photo")
    actual = fun.(:none, :lua)
    assert {[inspect({:something_else, "whoops"})], :lua} == actual
  end

  test "json_decode - OK" do
    actual = DataManipulation.json_decode(["{\"foo\":\"bar\"}"], :lua)
    assert {[[{"foo", "bar"}]], :lua} == actual
  end

  test "json_decode - Error" do
    actual = DataManipulation.json_decode(["no"], :lua)
    assert {[nil, "Error parsing JSON."], :lua} == actual
  end

  test "json_encode - OK" do
    actual = DataManipulation.json_encode([[{"foo", "bar"}]], :lua)
    assert {["{\"foo\":\"bar\"}"], :lua} == actual
  end

  test "env/1" do
    mock = fn -> [%__MODULE__{key: "foo", value: "bar"}] end
    expect(FarmbotOS.Asset, :list_farmware_env, 2, mock)
    results = DataManipulation.env(["foo"], :lua)
    assert {["bar"], :lua} == results
    results = DataManipulation.env(["wrong"], :lua)
    assert {[nil], :lua} == results
  end

  test "env/2 - OK" do
    mock = fn _, _ -> :ok end
    expect(FarmbotOS.SysCalls, :set_user_env, 1, mock)
    results = DataManipulation.env(["foo", "bar"], :lua)
    assert {["bar"], :lua} == results
  end

  test "env/2 - normal error" do
    mock = fn _, _ -> {:error, "reason"} end
    expect(FarmbotOS.SysCalls, :set_user_env, 1, mock)
    results = DataManipulation.env(["foo", "bar"], :lua)
    assert {[nil, "reason"], :lua} == results
  end

  test "env/2 - malformed error" do
    mock = fn _, _ -> :misc end
    expect(FarmbotOS.SysCalls, :set_user_env, 1, mock)
    results = DataManipulation.env(["foo", "bar"], :lua)
    assert {[nil, ":misc"], :lua} == results
  end

  defmodule FakeHackney do
    def request(_method, _url, _headers, _body, _options) do
      resp_headers = [
        {"Access-Control-Allow-Origin", "*"},
        {"Content-Length", "33"},
        {"Content-Type", "application/json; charset=utf-8"}
      ]

      {:ok, 200, resp_headers, make_ref()}
    end

    def body(_ref) do
      {:ok, "{\"whatever\": \"foo_bar_baz\"}"}
    end
  end

  test "http" do
    expect(FarmbotOS.HTTP, :hackney, 1, fn -> FakeHackney end)

    params =
      FarmbotOS.Lua.Util.map_to_table(%{
        "url" => "http://localhost:4567",
        "method" => "POST",
        "headers" => %{"foo" => "bar"},
        "body" => "{\"one\":\"two\"}"
      })

    expected = {
      [
        [
          {"body", "{\"whatever\": \"foo_bar_baz\"}"},
          {"headers",
           [
             {"Access-Control-Allow-Origin", "*"},
             {"Content-Length", "33"},
             {"Content-Type", "application/json; charset=utf-8"}
           ]},
          {"status", 200}
        ]
      ],
      :fake_lua
    }

    results = DataManipulation.http([params], :fake_lua)
    assert results == expected
  end

  @lua_code File.read!("#{:code.priv_dir(:farmbot)}/lua/photo_grid.lua")

  test "photo_grid() - OK" do
    expect(FarmbotOS.Lua, :raw_eval, 1, fn lua_state, lua_code ->
      assert lua_code == @lua_code
      assert lua_state == :fake_lua
      {:ok, :result}
    end)

    result = DataManipulation.photo_grid([], :fake_lua)
    assert result == {:result, :fake_lua}
  end

  test "photo_grid() - KO" do
    expect(FarmbotOS.Lua, :raw_eval, 1, fn lua_state, lua_code ->
      assert lua_code == @lua_code
      assert lua_state == :fake_lua
      {:error, :error_result}
    end)

    result = DataManipulation.photo_grid([], :fake_lua)
    assert result == {[nil, "ERROR: {:error, :error_result}"], :fake_lua}
  end
end
