defmodule FarmbotCore.FarmwareRuntimeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias FarmbotCore.FarmwareRuntime

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
    l = FarmbotCore.FarmwareLogger.new("test case")
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
