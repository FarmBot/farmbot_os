defmodule FarmbotCore.LogTest do
  alias FarmbotCore.Log
  use ExUnit.Case, async: true

  test "to_chars" do
    log = %Log{message: "Hello, world!"}
    assert "Hello, world!" = "#{log}"
  end
end
