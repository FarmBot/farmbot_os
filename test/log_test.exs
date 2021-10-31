defmodule FarmbotOS.LogTest do
  alias FarmbotOS.Log
  use ExUnit.Case

  test "to_chars" do
    log = %Log{message: "Hello, world!"}
    assert "Hello, world!" = "#{log}"
  end
end
