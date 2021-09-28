defmodule FarmbotCore.Celery.Compiler.PinControlTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotCore.Celery.Compiler.PinControl

  test "conclude/3" do
    expect(FarmbotCore.Celery.SysCalls, :read_pin, fn pin, mode ->
      assert pin == 1
      assert mode == 0
      :ok
    end)

    expect(FarmbotCore.Celery.SysCalls, :log, fn msg ->
      expected = "Pin 3 is 4 (analog)"
      assert msg == expected
      :ok
    end)

    PinControl.conclude(1, 0, 2)
    PinControl.conclude(3, 1, 4)
  end
end
