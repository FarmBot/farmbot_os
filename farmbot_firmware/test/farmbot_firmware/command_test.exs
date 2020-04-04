defmodule FarmbotFirmware.CommandTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotFirmware.Command
  import ExUnit.CaptureLog
  @subject FarmbotFirmware.Command

  @tag :capture_log
  test "command() runs RPCs" do
    arg = [transport: FarmbotFirmware.StubTransport]
    {:ok, pid} = FarmbotFirmware.start_link(arg, [])
    send(pid, :timeout)

    assert {:error, :emergency_lock} ==
             FarmbotFirmware.command(pid, {:command_emergency_lock, []})

    assert :ok == FarmbotFirmware.command(pid, {:command_emergency_unlock, []})
    cmd = {:parameter_write, [movement_stop_at_home_x: 0.0]}
    assert :ok == FarmbotFirmware.command(pid, cmd)
  end

  @tag :capture_log
  test "command() refuses to run RPCs in :boot state" do
    arg = [transport: FarmbotFirmware.StubTransport]
    {:ok, pid} = FarmbotFirmware.start_link(arg, [])
    send(pid, :timeout)
    {:error, message} = @subject.command(pid, {:a, {:b, :c}})
    assert "Can't send command when in :boot state" == message
  end

  test "enable_debug_logs" do
    Application.put_env(:farmbot_firmware, @subject, foo: :bar, debug_log: false)

    old_env = Application.get_env(:farmbot_firmware, @subject)

    assert false == Keyword.fetch!(old_env, :debug_log)
    assert :bar == Keyword.fetch!(old_env, :foo)
    assert false == @subject.debug?()

    refute capture_log(fn ->
             @subject.debug_log("Never Shown")
           end) =~ "Never Shown"

    # === Change ENV settings
    assert :ok ==
             Command.enable_debug_logs()

    assert capture_log(fn ->
             @subject.debug_log("Good!")
           end) =~ "Good!"

    assert true == @subject.debug?()
    new_env = Application.get_env(:farmbot_firmware, @subject)
    assert true == Keyword.fetch!(new_env, :debug_log)
    assert :bar == Keyword.fetch!(new_env, :foo)

    # === And back again
    assert :ok == Command.disable_debug_logs()
    even_newer = Application.get_env(:farmbot_firmware, @subject)

    assert false == Keyword.fetch!(even_newer, :debug_log)
    assert :bar == Keyword.fetch!(even_newer, :foo)
    assert false == @subject.debug?()

    refute capture_log(fn ->
             @subject.debug_log("Also Never Shown")
           end) =~ "Also Never Shown"
  end
end
