defmodule FramingFourByteTest do
  use ExUnit.Case
  alias Circuits.UART.Framing.FourByte

  test "frames 4 bytes at a time" do
    {:ok, framer} = FourByte.init([])

    test_bytes = <<1, 2, 3, 4>>
    {:ok, [test_bytes], ^framer} = FourByte.remove_framing(test_bytes, framer)

    {:ok, [test_bytes, test_bytes], ^framer} =
      FourByte.remove_framing(test_bytes <> test_bytes, framer)
  end

  test "buffers bytes" do
    {:ok, framer} = FourByte.init([])

    {:in_frame, [], framer} = FourByte.remove_framing(<<1>>, framer)
    {:in_frame, [], framer} = FourByte.remove_framing(<<2>>, framer)
    {:in_frame, [], framer} = FourByte.remove_framing(<<3>>, framer)
    {:ok, [<<1, 2, 3, 4>>], framer} = FourByte.remove_framing(<<4>>, framer)
    assert framer == <<>>

    {:in_frame, [], framer} = FourByte.remove_framing(<<5>>, framer)
    {:in_frame, [], framer} = FourByte.remove_framing(<<6, 7>>, framer)
    {:in_frame, [<<5, 6, 7, 8>>], framer} = FourByte.remove_framing(<<8, 9>>, framer)

    {:ok, [<<9, 10, 11, 12>>], _framer} = FourByte.remove_framing(<<10, 11, 12>>, framer)
  end

  test "flush works" do
    {:ok, framer} = FourByte.init([])

    {:in_frame, [], framer} = FourByte.remove_framing(<<1>>, framer)
    framer = FourByte.flush(:receive, framer)
    assert framer == <<>>

    {:ok, [<<1, 2, 3, 4>>], _framer} = FourByte.remove_framing(<<1, 2, 3, 4>>, framer)
  end

  test "timeout returns partial frame" do
    {:ok, framer} = FourByte.init([])

    {:in_frame, [], framer} = FourByte.remove_framing(<<1>>, framer)
    {:ok, [<<1>>], framer} = FourByte.frame_timeout(framer)
    assert framer == <<>>
  end
end
