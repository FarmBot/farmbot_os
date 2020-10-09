defmodule FarmbotCore.FarmwareRuntimeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias FarmbotCore.FarmwareRuntime

  test "stop/1" do
    fake_pid = spawn(fn -> 2 + 2 end)
    stop = fn -> FarmwareRuntime.stop(fake_pid) end
    assert capture_log(stop) =~ "Terminating farmware process"
  end
end
