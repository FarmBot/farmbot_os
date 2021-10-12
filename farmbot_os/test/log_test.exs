defmodule FarmbotCore.LogTest do
  alias FarmbotCore.Log
  use ExUnit.Case

  test "to_chars" do
    log = %Log{message: "Hello, world!"}
    assert "Hello, world!" = "#{log}"
  end
end
