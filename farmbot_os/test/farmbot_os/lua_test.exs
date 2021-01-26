defmodule FarmbotOS.LuaTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.Lua

  alias FarmbotOS.Lua.Ext.{
    Firmware,
    Info,
    DataManipulation
  }

  @tag :capture_log
  test "evaluates Lua" do
    assert Lua.eval_assertion("Returns 'true'", "return true")
    {:error, message1} = Lua.eval_assertion("Returns 'true'", "-1")

    assert message1 == "bad return value from expression evaluation"

    {:error, error} = Lua.eval_assertion("random error", "return (1/0)")
    assert error == :badarith
  end

  test "assertion logs" do
    # Hmmm
    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      assert log.level == "assertion"
      assert log.message == "this is an assertion"
      assert log.meta == %{assertion_passed: true, assertion_type: :assertion}
    end)

    Lua.log_assertion(true, :assertion, "this is an assertion")
  end

  @documentation_examples [
    "calibrate(\"x\")\ncalibrate(\"y\")\ncalibrate(\"z\")",
    "position = get_position()\nif position.x <= 20.55 then\n  return true\nelse\n  send_message(\"info\", \"X is: \" .. position.x)\n  return false\nend",
    "return get_position(\"y\") <= 20",
    "pins = get_pins()\npin9 = pins[9]\nif pins[9] == 1.0 then\n  return true\nend\nreturn get_pin(10) == 0",
    "find_home(\"x\")\nfind_home(\"y\")\nfind_home(\"z\")",
    "home(\"x\")\nhome(\"y\")\nhome(\"z\")",
    "move_absolute(1.0, 0, 0)\nmove_absolute(coordinate(1.0, 20, 30))",
    "move_absolute(1.0, 0, 0)\nreturn check_position({x = 1.0, y = 0,  z = 0}, 0.50)",
    "move_absolute(20, 100, 100)\nreturn check_position(coordinate(20, 100, 100), 1)",
    "return version() == \"12.3.4\"",
    "return get_device().timezone == \"America/los_angeles\"",
    "return get_device(\"name\") == \"Test Farmbot\"",
    "update_device({name = \"Test Farmbot\"})",
    "return get_fbos_config(\"auto_sync\")",
    "return get_fbos_config().os_auto_update",
    "update_fbos_config({auto_sync = true, os_auto_update = false})",
    "return get_firmware_config().encoder_enabled_x == 1.0",
    "return get_firmware_config(\"encoder_enabled_z\")",
    "update_firmware_config({encoder_enabled_z = 1.0})",
    "emergency_lock()",
    "emergency_unlock()",
    "send_message(\"info\", \"hello, world\", {\"toast\"})",
    "send_message(\"info\", x_pos, {\"toast\"})",
    "move_to = coordinate(1.0, 0, 0)",
    "status = read_status()",
    "return read_status(\"location_data\", \"raw_encoders\") >= 1900"
  ]
  test "documentation examples" do
    expect(Firmware, :calibrate, 3, fn
      [_axis], lua -> {[true], lua}
    end)

    expect(Firmware, :find_home, 3, fn
      [_axis], lua -> {[true], lua}
    end)

    expect(Firmware, :check_position, 2, fn
      _args, lua -> {[true], lua}
    end)

    expect(Firmware, :get_position, 2, fn
      [], lua -> {[[{"x", 1.23}, {"y", 1.23}, {"z", 1.23}]], lua}
      _, lua -> {[1.23], lua}
    end)

    expect(Firmware, :get_pins, 1, fn
      [], lua -> {[[{"9", 20.55}]], lua}
    end)

    expect(Firmware, :get_pin, 1, fn
      _, lua -> {[55.22], lua}
    end)

    expect(Firmware, :move_absolute, 1, fn
      _vec_or_xyz, lua -> {[55.22], lua}
    end)

    expect(Info, :version, 1, fn _args, lua ->
      {["12.3.4"], lua}
    end)

    expect(Info, :read_status, 2, fn
      ["location_data", "raw_encoders"], lua -> {[0], lua}
      hmm, lua -> {[0], lua}
    end)

    fake_device = [
      {"name", "Test Farmbot"},
      {"timezone", "America/los_angeles"}
    ]

    expect(DataManipulation, :get_device, 2, fn
      [], lua -> {[fake_device], lua}
      [_key], lua -> {["Test Farmbot"], lua}
    end)

    expect(DataManipulation, :update_device, 1, fn
      [[{"name", "Test Farmbot"}]], lua -> {[], lua}
    end)

    expect(DataManipulation, :get_fbos_config, 2, fn
      [], lua -> {[[{"os_auto_update", true}]], lua}
      ["auto_sync"], lua -> {[true], lua}
    end)

    expect(DataManipulation, :get_firmware_config, 2, fn
      [], lua -> {[[{"encoder_enabled_x", 1.0}]], lua}
      ["encoder_enabled_z"], lua -> {[], lua}
    end)

    expect(DataManipulation, :update_firmware_config, 1, fn
      [[{"encoder_enabled_z", 1.0}]], lua -> {[], lua}
    end)

    expect(Firmware, :emergency_lock, 1, fn [], lua ->
      {[], lua}
    end)

    expect(Firmware, :emergency_unlock, 1, fn [], lua ->
      {[], lua}
    end)

    expect(Info, :send_message, 2, fn
      ["info", "hello, world", [{1, "toast"}]], lua -> {[], lua}
      ["info", nil, [{1, "toast"}]], lua -> {[], lua}
    end)

    Enum.map(@documentation_examples, fn lua ->
      result = Lua.raw_lua_eval(lua)

      case result do
        {:ok, _} ->
          nil

        {:error, expl} ->
          {a, b, _c} = expl
          IO.inspect({a, b}, label: "== Result")
          raise "NO"
      end
    end)
  end
end
