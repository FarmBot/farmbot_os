defmodule FarmbotOS.LuaTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.Lua

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
    # "-- Returns a table containing the current position data\n\nposition = get_position()\nif position.x <= 20.55 then\n  return true;\nelse\n  send_message(\"info\", \"X is: \" .. position.x)\n  return false\nend\n",
    # "-- Read a single axis\nreturn get_position(\"y\") <= 20\n",
    # "-- Returns a table containing current pin data\n\npins = get_pins()\npin9 = pins[9]\nif pins[9] == 1.0 then\n  return true\nend\n\nreturn get_pin(10) == 0\n",
    # "-- Calibrate an axis\n\ncalibrate(\"x\")\ncalibrate(\"y\")\ncalibrate(\"z\")\n",
    # "-- Find home on an axis\n\nfind_home(\"x\")\nfind_home(\"y\")\nfind_home(\"z\")\n",
    # "-- Go to home on an axis\n\nhome(\"x\")\nhome(\"y\")\nhome(\"z\")\n",
    # "-- Create a vec3\n\nmove_to = coordinate(1.0, 0, 0)\n",
    # "-- Move in a line to a position\n\nmove_absolute(1.0, 0, 0)\nmove_absolute(coordinate(1.0, 20, 30))\n",
    # "-- Check a position against Farmbot's current position within an error threshold\n\nmove_absolute(1.0, 0, 0)\nreturn check_position({x = 1.0, y = 0,  z = 0}, 0.50)\n",
    # "move_absolute(20, 100, 100);\nreturn check_position(coordinate(20, 100, 100), 1);\n",
    # "-- Get a field on farmbot's current state\n\nstatus = read_status();\nreturn status.informational_settings.wifi_level >= 5;\n\nreturn read_status(\"location_data\", \"raw_encoders\") >= 1900;\n",
    # "-- Return Farmbot's current version\n\nreturn version() == \"12.3.4\";\n",
    # "-- Return the device settings\n\nreturn get_device().timezone == \"America/los_angeles\";\n\nreturn get_device(\"name\") == \"Test Farmbot\";\n",
    # "-- Update device settings\n\nupdate_device({name = \"Test Farmbot\"});\n",
    # "-- Return the current fbos_config\n\nreturn get_fbos_config(\"auto_sync\");\nreturn get_fbos_config().os_auto_update;\n",
    # "-- Update the current fbos_config\n\nupdate_fbos_config({auto_sync = true, os_auto_update = false});\n",
    # "-- Return current firmware_config data\n\nreturn get_firmware_config().encoder_enabled_x == 1.0;\n\nreturn get_firmware_config(\"encoder_enabled_z\");\n",
    # "-- Update current firmware_config data\n\nupdate_firmware_config({encoder_enabled_z = 1.0});\n",
    # "-- send_message(type, message, channels)\n-- Sends a message to farmbot's logger\n\nsend_message(\"info\", \"hello, world\", {\"toast\"})\n",
    # "-- Lock and unlock farmbot's firmware\n\nemergency_lock()\nemergency_unlock()\n",
    # "x_pos = variables.parent.x\nsend_message(\"info\", x_pos, {\"toast\"});\n",
  ]
  test "documentation examples" do
    # System.cmd("clear", [])
    IO.puts("==== Finish writing these tests!!")

    Enum.map(@documentation_examples, fn lua ->
      IO.puts(lua)
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
