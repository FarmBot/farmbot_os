defmodule FarmbotOS.LuaTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.Firmware.Command
  alias FarmbotOS.Lua

  alias FarmbotOS.Lua.{
    Firmware,
    Info,
    DataManipulation
  }

  test "do_gcode" do
    expect(FarmbotOS.Firmware.UARTCore, :start_job, 1, fn gcode ->
      assert gcode.command == "G00"
      assert gcode.echo == nil
      assert gcode.params == [X: 10, Y: 20, Z: 30]
      assert gcode.string == "G00 X10.00 Y20.00 Z30.00"
      {:ok, nil}
    end)

    result = Lua.do_gcode(["G00", [{"x", 10}, {"y", 20}, {"z", 30}]], %{})
    assert {[], %{}} = result
  end

  test "job setters/getters" do
    fns = Lua.builtins()
    name = "foo"
    args = [type: "bar", status: "baz", percent: 42.0]
    lua = %{}
    result = fns.set_job_progress.([name, args], lua)
    assert result == {[], %{}}
    {[result2], %{}} = fns.get_job_progress.([name], lua)
    assert result2.unit == "percent"
  end

  @tag :capture_log
  test "evaluates Lua" do
    val1 = Lua.perform_lua("true", [], "Returns 'true'")
    assert {:ok, [true]} == val1

    val2 = Lua.perform_lua("-1", [], "Returns -1")
    assert {:ok, [-1]} == val2

    val3 = Lua.perform_lua("(1/0)", [], "random error")
    assert {:error, "Lua failure"} == val3
  end

  test "soft_stop" do
    expect(FarmbotOS.Firmware.Command, :abort, 1, fn ->
      :ok
    end)

    assert Firmware.soft_stop([], :fake_lua) == {[], :fake_lua}
  end

  test "assertion logs" do
    # Hmmm
    expect(FarmbotOS.LogExecutor, :execute, 1, fn log ->
      assert log.level == "assertion"
      assert log.message == "this is an assertion"
      assert log.meta == %{assertion_passed: true, assertion_type: :assertion}
    end)

    FarmbotOS.SysCalls.log_assertion(true, :assertion, "this is an assertion")
  end

  @documentation_examples [
    "emergency_lock()",
    "emergency_unlock()",
    "find_axis_length(\"x\")\nfind_axis_length(\"y\")\nfind_axis_length(\"z\")",
    "find_home(\"x\")\nfind_home(\"y\")\nfind_home(\"z\")",
    "firmware_version()",
    "get_device(\"name\")",
    "get_fbos_config().os_auto_update",
    "get_fbos_config(\"os_auto_update\")",
    "get_firmware_config().encoder_enabled_x",
    "get_firmware_config(\"encoder_enabled_z\")",
    "go_to_home(\"all\")",
    "go_to_home(\"x\")\ngo_to_home(\"y\")\ngo_to_home(\"z\")",
    "go_to_home()",
    "move_absolute(1.0, 0, 0)\ncheck_position({x = 1.0, y = 0,  z = 0}, 0.50)",
    "move_absolute(1.0, 0, 0)\nmove_absolute(coordinate(1.0, 20, 30))",
    "move_absolute(20, 100, 100)\ncheck_position(coordinate(20, 100, 100), 1)",
    "move_to = coordinate(1.23, 0, 0)",
    "pin23 = read_pin(23, \"analog\")",
    "pin24 = read_pin(24) -- Digital is the default",
    "position = get_position()\nif position.x <= 20.55 then\n  return true\nelse\n  send_message(\"info\", \"X is: \" .. position.x)\n  return false\nend",
    "position, error = get_position(\"y\")\nif error then\n send_message(\"error\", error, \"toast\")\nend",
    "read_status(\"location_data\", \"raw_encoders\", \"x\") > 23",
    "send_message(\"info\", \"hello, world\", {\"toast\"})",
    "send_message(\"info\", \"Running FBOS v\" .. fbos_version())",
    "send_message(\"info\", \"Time zone is: \" .. get_device().timezone)",
    "send_message(\"info\", 23, {\"toast\"})",
    "status = read_status()",
    "update_device({name = \"Test Farmbot\"})",
    "update_fbos_config({os_auto_update = false})",
    "update_firmware_config({encoder_enabled_z = 1.0})",
    "variable().x",
    "variable(\"parent\").x",
    "variables().x",
    "variables(\"parent\").x",
    "write_pin(13, \"analog\", 64)"
  ]
  test "documentation examples" do
    expect(Firmware, :calibrate, 3, fn [_axis], lua -> {[true], lua} end)
    expect(Firmware, :check_position, 2, fn _args, lua -> {[true], lua} end)
    expect(Firmware, :emergency_lock, 1, fn [], lua -> {[], lua} end)
    expect(Firmware, :emergency_unlock, 1, fn [], lua -> {[], lua} end)
    expect(Firmware, :find_home, 3, fn [_axis], lua -> {[true], lua} end)
    expect(Firmware, :read_pin, 1, fn _, lua -> {[55.22], lua} end)
    expect(Firmware, :write_pin, 1, fn _, lua -> {[], lua} end)
    expect(Firmware, :go_to_home, 4, fn [_axis], lua -> {[true], lua} end)
    expect(Info, :fbos_version, 1, fn _args, lua -> {["12.3.4"], lua} end)
    expect(Info, :firmware_version, 1, fn _args, lua -> {["12.3.4"], lua} end)
    expect(Info, :read_status, 2, fn _other, lua -> {[0], lua} end)
    expect(Info, :send_message, 4, fn _, lua -> {[], lua} end)

    expect(DataManipulation, :update_device, 1, fn [[{"name", "Test Farmbot"}]],
                                                   lua ->
      {[], lua}
    end)

    expect(Command, :read_pin, 1, fn _, _ -> {:ok, 1} end)

    expect(Firmware, :move_absolute, 4, fn _vec_or_xyz, lua ->
      {[55.22], lua}
    end)

    expect(Firmware, :get_position, 2, fn
      [], lua -> {[[{"x", 1.23}, {"y", 1.23}, {"z", 1.23}], nil], lua}
      _, lua -> {[1.23, nil], lua}
    end)

    expect(DataManipulation, :get_device, 2, fn
      [], lua ->
        {[
           [
             {"name", "Test Farmbot"},
             {"timezone", "America/los_angeles"}
           ]
         ], lua}

      [_key], lua ->
        {["Test Farmbot"], lua}
    end)

    expect(DataManipulation, :get_fbos_config, 2, fn
      [], lua -> {[[{"os_auto_update", true}]], lua}
      _, lua -> {[true], lua}
    end)

    expect(DataManipulation, :get_firmware_config, 2, fn
      [], lua -> {[[{"encoder_enabled_x", 1.0}]], lua}
      ["encoder_enabled_z"], lua -> {[], lua}
    end)

    expect(DataManipulation, :update_firmware_config, 1, fn
      [[{"encoder_enabled_z", 1.0}]], lua -> {[], lua}
    end)

    Enum.map(@documentation_examples, fn lua ->
      scope = %FarmbotOS.Celery.Compiler.Scope{
        declarations: %{
          "parent" => %{"x" => 1000}
        },
        parent: nil
      }

      extra_vm_args = FarmbotOS.Celery.Compiler.Lua.scope_to_lua(scope)
      result = FarmbotOS.Lua.perform_lua(lua, extra_vm_args, lua)

      case result do
        {:ok, _} ->
          nil

        error ->
          IO.puts("===== A LUA EXAMPLE IS BROKE:")
          IO.puts(lua)
          IO.inspect(error, label: "=== This is the error")
          raise "NO!: #{inspect(error)}"
      end
    end)
  end
end
