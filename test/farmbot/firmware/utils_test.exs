defmodule Farmbot.Firmware.UtilsTest do
  use ExUnit.Case
  alias Farmbot.Firmware.Utils

  test "changes number values into booleans" do
    assert Utils.num_to_bool(1)
    assert Utils.num_to_bool(1.0)
    refute Utils.num_to_bool(0)

    assert_raise FunctionClauseError, fn() ->
      Utils.num_to_bool(1.1)
    end

    assert_raise FunctionClauseError, fn() ->
      Utils.num_to_bool(nil)
    end
  end

  test "formats a number into a string that looks correct" do
    assert Utils.fmnt_float(1) == "1.0"
    assert Utils.fmnt_float(0) == "0.0"
    assert Utils.fmnt_float(1.0) == "1.0"
    assert Utils.fmnt_float(20.0) == "20.0"
    assert Utils.fmnt_float(100.0) == "100.0"
    assert Utils.fmnt_float(100) == "100.0"
    assert Utils.fmnt_float(120.22) == "120.22"
  end

  test "Extracts pinmode from an atom" do
    assert Utils.extract_pin_mode(:digital) == 0
    assert Utils.extract_pin_mode(:analog) == 1
    assert_raise FunctionClauseError, fn() ->
      Utils.extract_pin_mode(:whoops)
    end
  end

  test "Extracts set_pin_mode from an atom" do
    assert Utils.extract_set_pin_mode(:input) == 0
    assert Utils.extract_set_pin_mode(:input_pullup) == 2
    assert Utils.extract_set_pin_mode(:output) == 1
    assert_raise FunctionClauseError, fn() ->
      Utils.extract_set_pin_mode(:whoops)
    end
  end
end
