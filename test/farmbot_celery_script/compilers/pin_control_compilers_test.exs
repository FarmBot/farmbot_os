defmodule FarmbotOS.Celery.Compiler.PinControlTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotOS.Celery.Compiler.PinControl

  test "conclude/3" do
    expect(FarmbotOS.Celery.SysCallGlue, :read_pin, fn pin, mode ->
      assert pin == 1
      assert mode == 0
      :ok
    end)

    expect(FarmbotOS.Celery.SysCallGlue, :log, fn msg ->
      expected = "Pin 3 is 4 (analog)"
      assert msg == expected
      :ok
    end)

    PinControl.conclude(1, 0, 2)
    PinControl.conclude(3, 1, 4)
  end
end
