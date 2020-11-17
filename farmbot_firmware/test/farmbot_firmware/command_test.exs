defmodule FarmbotFirmware.CommandTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  @subject FarmbotFirmware.Command

  def fake_pid() do
    arg = [transport: FarmbotFirmware.StubTransport, reset: StubReset]
    {:ok, pid} = FarmbotFirmware.start_link(arg, [])
    send(pid, :timeout)
    pid
  end

  @tag :capture_log
  test "command() runs RPCs" do
    pid = fake_pid()

    assert {:error, :emergency_lock} ==
             FarmbotFirmware.command(pid, {:command_emergency_lock, []})

    assert :ok == FarmbotFirmware.command(pid, {:command_emergency_unlock, []})
    cmd = {:parameter_write, [movement_stop_at_home_x: 0.0]}
    assert :ok == FarmbotFirmware.command(pid, cmd)
  end

  @tag :capture_log
  test "command() refuses to run RPCs in :boot state" do
    pid = fake_pid()
    {:error, message} = @subject.command(pid, {:a, {:b, :c}})
    assert "Can't send command when in :boot state" == message
  end
end
