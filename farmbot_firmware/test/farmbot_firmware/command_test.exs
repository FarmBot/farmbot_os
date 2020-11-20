defmodule FarmbotFirmware.CommandTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

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

  def do_spawn_my_test(caller, code) do
    result = FarmbotFirmware.Command.wait_for_command_result(code)
    send(caller, result)
  end

  def spawn_my_test() do
    # Spawn a fake GCode command.
    # For the sake of tests, we will
    # simulate a "parameter_read_all"
    # command.
    spawn(__MODULE__, :do_spawn_my_test, [
      self(),
      {nil, {:parameter_read_all, []}}
    ])
  end

  test "handle {:error, message} from firmware" do
    pid = spawn_my_test()
    my_error = {:error, "foo bar baz"}
    send(pid, my_error)
    assert_receive(my_error, 500, "Expected firmware errors to be echoed")
  end

  test "handle a retry that turns in to an estop error" do
    pid = spawn_my_test()
    send(pid, {nil, {:report_retry, []}})
    send(pid, {nil, {:report_emergency_lock, []}})

    assert_receive(
      {:error, :emergency_lock},
      500,
      "Expected firmware errors to be echoed"
    )
  end
end
