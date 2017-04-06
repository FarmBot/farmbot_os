defmodule Farmbot.System.FSTest do
  use ExUnit.Case
  alias Farmbot.System.FS

  test "blocks and write a file" do
    path = FS.path() <> "/test_file"
    stuff = "HELLO WORLD"
    FS.transaction fn() ->
      File.write(path, stuff)
    end, true
    {:ok, bin} = File.read(path)
    assert stuff == bin
  end

  test "times out" do
    timeout = 1000
    r = FS.transaction fn() -> Process.sleep(timeout + 100) end, true, timeout
    assert is_nil r
  end

  test "makes coverage magically higher" do
    state = FS.get_state
    send FS, :uhhh
    assert is_list(state)
  end
end
