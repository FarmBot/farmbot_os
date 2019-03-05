defmodule FarmbotCeleryScript.Corpus.NodeTest do
  use ExUnit.Case, async: true
  alias FarmbotCeleryScript.Corpus

  test "inspect" do
    assert "Sequence(version, locals) [_if, execute, execute_script, find_home, move_absolute, move_relative, read_pin, send_message, take_photo, wait, write_pin, resource_update]" =
             inspect(Corpus.sequence())
  end
end
