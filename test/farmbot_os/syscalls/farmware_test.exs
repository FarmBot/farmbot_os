defmodule FarmbotOS.SysCalls.FarmwareTest do
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!

  test "farmware_timeout" do
    fake_pid = :FAKE_PID

    expect(FarmbotOS.LogExecutor, :execute, fn log ->
      expected =
        "Farmware did not exit after 20.0 minutes. Terminating :FAKE_PID"

      assert log.message == expected
      :ok
    end)

    expect(FarmbotOS.FarmwareRuntime, :stop, fn pid ->
      assert pid == fake_pid
    end)

    assert :ok == FarmbotOS.SysCalls.Farmware.farmware_timeout(fake_pid)
  end
end
