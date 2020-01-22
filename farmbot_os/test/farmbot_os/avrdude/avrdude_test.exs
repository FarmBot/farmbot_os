defmodule FarmbotOs.AvrdudeTest do
  use ExUnit.Case

  use Mimic

  setup [:verify_on_exit!]

  test "works" do
    File.touch("/tmp/wow")

    expect(Avrdude.MuonTrapAdapter, :cmd, fn cmd, args, opts ->
      assert cmd == "avrdude"

      assert args == [
               "-patmega2560",
               "-cwiring",
               "-P/dev/null",
               "-b115200",
               "-D",
               "-V",
               "-Uflash:w:/tmp/wow:i"
             ]

      assert opts == [
               into: %IO.Stream{
                 device: :standard_io,
                 line_or_bytes: :line,
                 raw: false
               },
               stderr_to_stdout: true
             ]
    end)

    Avrdude.flash("/tmp/wow", "null", fn ->
      "YOLO"
    end)
  end
end
