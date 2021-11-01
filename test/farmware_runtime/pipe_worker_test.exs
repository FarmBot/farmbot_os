defmodule FarmbotOS.FarmwareRuntime.PipeWorkerTest do
  use ExUnit.Case
  use Mimic
  import ExUnit.CaptureLog
  alias FarmbotOS.FarmwareRuntime.PipeWorker
  setup :verify_on_exit!

  defmodule FakeState do
    defstruct [:direction, :pipe_name, :pipe]
  end

  test "terminate/2" do
    state = %FakeState{
      direction: "direction",
      pipe_name: "/tmp/farmbot_os_test_pipe",
      pipe: nil
    }

    msg = "PipeWorker #{state.direction} #{state.pipe_name} exit"
    File.touch(state.pipe_name)
    terminate = fn -> PipeWorker.terminate(nil, state) end
    assert capture_log(terminate) =~ msg
  end
end
