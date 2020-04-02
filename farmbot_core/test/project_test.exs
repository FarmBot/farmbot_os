defmodule FarmbotCore.ProjectTest do
  use ExUnit.Case

  test "arduino_commit" do
    actual = FarmbotCore.Project.arduino_commit()
    expected = "0c4b14eb1bec8d466fbb815bfd7ee13b0b2d8c91"
    assert expected == actual
  end
end
