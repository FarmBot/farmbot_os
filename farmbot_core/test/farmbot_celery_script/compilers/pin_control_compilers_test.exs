defmodule FarmbotCeleryScript.Compiler.PinControlTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotCeleryScript.Compiler.PinControl

  test "conclude/3" do
    expect(FarmbotCeleryScript.SysCalls, :read_pin, fn pin, mode ->
      assert pin == 1
      assert mode == 0
      :ok
    end)

    expect(FarmbotCeleryScript.SysCalls, :log, fn msg ->
      expected = "Pin 3 is 4 (analog)"
      assert msg == expected
      :ok
    end)

    PinControl.conclude(1, 0, 2)
    PinControl.conclude(3, 1, 4)
  end
end
