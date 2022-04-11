defmodule FarmbotOS.FarmwareRuntime.RunCommandTest do
  alias FarmbotOS.FarmwareRuntime.RunCommand
  use ExUnit.Case

  test "run" do
    {cmd, _} = RunCommand.run(["sh", []])
    assert is_pid(cmd)
  end
end
