defmodule FarmbotCore.ProjectTest do
  use ExUnit.Case
  @opts [cd: Path.join("c_src", "farmbot-arduino-firmware")]

  test "arduino_commit" do
    actual = FarmbotCore.Project.arduino_commit()
    assert is_binary(actual)
    assert String.length(actual) == 40
  end
end
