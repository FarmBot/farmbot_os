defmodule FarmbotOs.AvrdudeTest do
  use ExUnit.Case

  use Mimic

  setup :verify_on_exit!

  test "failure handling" do
    reset_fn = fn ->
      raise RuntimeError, "foo"
    end

    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
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
               "-b115200",
               "-D",
               "-V",
               "-v",
               "-Uflash:w:/tmp/wow:i"
             ]

      assert opts == [
               #  into: %IO.Stream{
               #    device: :standard_io,
               #    line_or_bytes: :line,
               #    raw: false
               #  },
               stderr_to_stdout: true
             ]
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
               "-b115200",
               "-D",
               "-V",
               "-v",
               "-Uflash:w:/tmp/wow:i"
             ]

      assert opts == [
               #  into: %IO.Stream{
               #    device: :standard_io,
               #    line_or_bytes: :line,
               #    raw: false
               #  },
               stderr_to_stdout: true
             ]
    end)

    Avrdude.flash("/tmp/wow", "/dev/null", fn ->
      "YOLO"
    end)
  end
end
