defmodule FarmbotOS.FarmwareRuntimeTest do
  use ExUnit.Case
  use Mimic
  import ExUnit.CaptureLog
  alias FarmbotOS.FarmwareRuntime

  test "init" do
    for [package, expected_name] <- [
          ["noop", "Executing noop"],
          ["camera-calibration", "Calibrating camera"],
          ["historical-camera-calibration", "Calibrating camera"],
          ["historical-plant-detection", "Running weed detector"],
          ["plant-detection", "Running weed detector"],
          ["take-photo", "Taking photo"],
          ["Measure Soil Height", "Measuring soil height"]
        ] do
      expect(FarmwareRuntime.RunCommand, :run, 1, fn [cmd, args, opts] ->
        assert cmd == "sh"
        assert args |> Enum.at(0) == "-c"
        {:into, logger} = opts |> Enum.at(2)
        assert logger == %FarmbotOS.FarmwareLogger{name: package}
        spawn_monitor(File, :ls, [])
      end)

      expect(FarmbotOS.BotState, :set_job_progress, 1, fn name, progress ->
        assert name == expected_name
        assert progress.percent == 50
      end)

      t = fn ->
        {:ok, state} = FarmwareRuntime.init([package, %{}, self()])
        assert state.caller == self()
        assert is_pid(state.cmd)
        assert state.context == :get_header
        assert state.mon == nil
        assert state.request_pipe =~ "-farmware-request-pipe"
        assert is_pid(state.request_pipe_handle)
        assert state.response_pipe =~ "-farmware-response-pipe"
        assert is_pid(state.response_pipe_handle)
        assert state.rpc == nil
        assert state.scheduler_ref == nil
      end

      assert capture_log(t) =~ "opening pipe: /tmp/farmware_runtime/#{package}-"
    end
  end

  test "error handling" do
    state = %FarmwareRuntime{
      scheduler_ref: make_ref(),
      caller: self()
    }

    error = {:error, "intentional error (unit test)"}
    message = {:csvm_done, state.scheduler_ref, error}
    {:noreply, next_state} = FarmwareRuntime.handle_info(message, state)
    refute next_state.scheduler_ref
    assert_receive ^error, 5000
  end

  test "exit" do
    state = %FarmwareRuntime{
      package: "package",
      scheduler_ref: make_ref(),
      caller: self(),
      start_time: 0
    }

    expect(FarmbotOS.BotState, :set_job_progress, 1, fn name, progress ->
      assert name == "Executing package"

      assert progress == %FarmbotOS.BotState.JobProgress.Percent{
               percent: 100,
               status: "Complete",
               time: state.start_time,
               type: "package"
             }
    end)

    message = {:DOWN, state.scheduler_ref, :process, state.cmd, ""}
    farmware_exit = fn -> FarmwareRuntime.handle_info(message, state) end
    assert capture_log(farmware_exit) =~ "Farmware exit"
  end

  test "stop/1" do
    fake_pid = spawn(fn -> 2 + 2 end)
    stop = fn -> FarmwareRuntime.stop(fake_pid) end
    assert capture_log(stop) =~ "Terminating farmware process"
  end

  test "logger related helpers" do
    l = FarmbotOS.FarmwareLogger.new("test case")
    {logger, fun} = Collectable.into(l)
    assert l == logger
    assert is_function(fun)

    t1 = fn ->
      fun.(l, {:cont, "my test case 123"})
      assert l == fun.(l, :done)
      assert :ok == fun.(l, :halt)
    end

    assert capture_log(t1) =~ "[debug] [\"test case\"] my test case 123"
  end
end
