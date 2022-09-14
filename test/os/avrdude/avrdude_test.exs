defmodule FarmbotOs.AvrdudeTest do
  alias FarmbotOS.Firmware.Avrdude
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!

  test "failure handling" do
    reset_fn = fn ->
      raise RuntimeError, "foo"
    end

    expect(FarmbotOS.LogExecutor, :execute, 1, fn log ->
      msg = log.message
      assert String.contains?(msg, "%RuntimeError{message: \"foo\"}")
    end)

    Avrdude.call_reset_fun(reset_fn)
  end

  test "works" do
    File.touch("/tmp/wow")

    expect(MuonTrap, :cmd, 1, fn cmd, args, opts ->
      assert cmd == "avrdude"

      assert args == [
               "-patmega2560",
               "-cwiring",
               "-P/dev/null",
               "-b57600,
               "-D",
               "-V",
               "-v",
               "-Uflash:w:/tmp/wow:i"
             ]

      assert opts == [stderr_to_stdout: true]
      {"hello", 0}
    end)

    Avrdude.flash("/tmp/wow", "null", fn ->
      "YOLO"
    end)
  end

  test "handles /dev file names, also" do
    File.touch("/tmp/wow")

    expect(MuonTrap, :cmd, 1, fn cmd, args, opts ->
      assert cmd == "avrdude"

      assert args == [
               "-patmega2560",
               "-cwiring",
               "-P/dev/null",
               "-b57600",
               "-D",
               "-V",
               "-v",
               "-Uflash:w:/tmp/wow:i"
             ]

      assert opts == [stderr_to_stdout: true]
      {"foo", 0}
    end)

    Avrdude.flash("/tmp/wow", "/dev/null", fn ->
      "YOLO"
    end)
  end
end
