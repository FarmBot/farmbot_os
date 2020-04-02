defmodule FarmbotCore.ProjectTest do
  use ExUnit.Case
  @opts [cd: Path.join("c_src", "farmbot-arduino-firmware")]

  test "arduino_commit" do
    actual = FarmbotCore.Project.arduino_commit()

    expected =
      System.cmd("git", ~w"rev-parse --verify HEAD", @opts)
      |> elem(0)
      |> String.trim()

    assert expected == actual
  end
end
