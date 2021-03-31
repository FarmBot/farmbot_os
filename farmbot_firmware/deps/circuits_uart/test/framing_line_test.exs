defmodule FramingLineTest do
  use ExUnit.Case
  alias Circuits.UART.Framing.Line

  test "adds framing" do
    {:ok, line} = Line.init(separator: "\n")
    assert {:ok, "\n", ^line} = Line.add_framing("", line)
    assert {:ok, "ABC\n", ^line} = Line.add_framing("ABC", line)
  end

  test "removes framing using newline" do
    {:ok, line} = Line.init(separator: "\n")
    assert {:ok, [""], ^line} = Line.remove_framing("\n", line)
    assert {:ok, ["ABC"], ^line} = Line.remove_framing("ABC\n", line)
    assert {:ok, ["ABC", "DEF"], ^line} = Line.remove_framing("ABC\nDEF\n", line)
  end

  test "clears framing buffer on flush" do
    {:ok, line} = Line.init([])

    assert {:in_frame, [], line} = Line.remove_framing("ABC", line)
    assert line.processed == "ABC"

    line = Line.flush(:receive, line)
    assert Line.buffer_empty?(line) == true
  end

  test "handles partial lines" do
    {:ok, line} = Line.init(separator: "\n")

    assert {:in_frame, [], line} = Line.remove_framing("ABC", line)
    assert {:ok, ["ABC"], line} = Line.remove_framing("\n", line)

    assert {:in_frame, ["DEF"], line} = Line.remove_framing("DEF\nGH", line)
    assert {:ok, ["GH"], line} = Line.remove_framing("\n", line)

    assert Line.buffer_empty?(line) == true
  end

  test "removes framing using crlf" do
    {:ok, line} = Line.init(separator: "\r\n")

    assert {:ok, [""], line} = Line.remove_framing("\r\n", line)
    assert {:ok, ["ABC"], line} = Line.remove_framing("ABC\r\n", line)
    assert {:ok, ["ABC", "DEF"], line} = Line.remove_framing("ABC\r\nDEF\r\n", line)

    assert Line.buffer_empty?(line) == true
  end

  test "handles partial framing using crlf" do
    {:ok, line} = Line.init(separator: "\r\n")

    assert {:in_frame, [], line} = Line.remove_framing("ABC", line)
    assert {:ok, ["ABC"], line} = Line.remove_framing("\r\n", line)

    assert {:in_frame, [], line} = Line.remove_framing("DEF\r", line)
    assert {:ok, ["DEF"], line} = Line.remove_framing("\n", line)

    assert {:in_frame, ["GHI"], line} = Line.remove_framing("GHI\r\nJKL\r", line)
    assert {:ok, ["JKL"], line} = Line.remove_framing("\n", line)

    assert {:in_frame, [], line} = Line.remove_framing("M", line)
    assert {:in_frame, [], line} = Line.remove_framing("N", line)
    assert {:in_frame, [], line} = Line.remove_framing("O", line)
    assert {:in_frame, [], line} = Line.remove_framing("\r", line)
    assert {:ok, ["MNO"], line} = Line.remove_framing("\n", line)

    assert Line.buffer_empty?(line) == true
  end

  test "handles max length" do
    {:ok, line} = Line.init(max_length: 4)

    # One partial result
    assert {:in_frame, [{:partial, "ABCD"}], line} = Line.remove_framing("ABCDEFG", line)
    assert {:ok, ["EFG"], line} = Line.remove_framing("\n", line)

    # Multiple partial results
    assert {:in_frame, [{:partial, "ABCD"}, {:partial, "EFGH"}], line} =
             Line.remove_framing("ABCDEFGHI", line)

    # Add one by one to get a partial result
    assert {:in_frame, [], line} = Line.remove_framing("J", line)
    assert {:in_frame, [], line} = Line.remove_framing("K", line)
    assert {:in_frame, [], line} = Line.remove_framing("L", line)
    assert {:in_frame, [{:partial, "IJKL"}], line} = Line.remove_framing("M", line)
    assert Line.buffer_empty?(line) == false
  end

  test "handles max length at end of line" do
    {:ok, line} = Line.init(max_length: 4)
    assert {:ok, ["ABCD"], ^line} = Line.remove_framing("ABCD\n", line)

    assert {:in_frame, [], line} = Line.remove_framing("EFGH", line)
    assert {:ok, ["EFGH"], line} = Line.remove_framing("\n", line)

    assert Line.buffer_empty?(line) == true
  end
end
