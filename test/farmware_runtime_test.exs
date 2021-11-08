defmodule FarmbotOS.FarmwareRuntimeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias FarmbotOS.FarmwareRuntime

  test "init" do
    t = fn ->
      {:ok, state} = FarmwareRuntime.init(["noop", %{}, self()])
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

    assert capture_log(t) =~ "opening pipe: /tmp/farmware_runtime/noop-"
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
