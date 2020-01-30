defmodule FarmbotFirmware.CommandTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotFirmware.Command
  import ExUnit.CaptureLog
  @subject FarmbotFirmware.Command

  def firmware_server do
    arg = [transport: FarmbotFirmware.StubTransport]
    {:ok, pid} = FarmbotFirmware.start_link(arg, [])
    pid
  end

  def try_command(cmd, pid \\ firmware_server()) do
    @subject.command(pid, cmd)
  end

  @tag :this_is_the_bug
  test "direct call (delete this later)" do
    pid = firmware_server()

    {:error, result} =
      GenServer.call(pid, {:command_emergency_lock, []}, :infinity)

    assert result == :transport_boot
  end

  @tag :skip
  test "various command()s" do
    assert {:ok, nil} == try_command({:command_emergency_lock, []})
    assert {:ok, "1"} == try_command({:pin_mode_write, [p: 13, m: 1]})
    assert {:ok, "1"} == try_command({"1", {:position_write_zero, [:x]}})

    assert {:ok, "23"} ==
             try_command(
               {"23", {:parameter_write, [movement_invert_2_endpoints_y: 1.0]}}
             )

    assert {:ok, "24"} ==
             try_command(
               {"24", {:parameter_write, [movement_stop_at_home_x: 0.0]}}
             )

    assert {:ok, "40"} == try_command({"40", {:pin_write, [p: 13, v: 0, m: 0]}})
    assert {:ok, "49"} == try_command({"49", {:pin_mode_write, [p: 13, m: 1]}})
    assert {:ok, "55"} == try_command({"55", {:pin_mode_write, [p: 13, m: 1]}})
    assert {:ok, "59"} == try_command({"59", {:pin_mode_write, [p: 13, m: 1]}})

    assert {:ok, "94"} ==
             try_command({"94", {:parameter_write, [movement_home_up_y: 1.0]}})

    assert {:ok, "94"} == try_command({"94", {:pin_write, [p: 13, v: 1, m: 0]}})

    assert {:ok, "98"} ==
             try_command({"98", {:parameter_write, [movement_home_up_y: 0.0]}})

    assert {:ok, "99"} ==
             try_command(
               {"99", {:parameter_write, [movement_stop_at_home_x: 1.0]}}
             )

    assert {:ok, nil} == try_command({nil, {:command_emergency_lock, []}})
    assert {:ok, nil} == try_command({nil, {:command_emergency_lock, []}})

    assert {:ok, nil} ==
             try_command(
               {nil,
                {:command_movement,
                 [x: 0.0, y: 0.0, z: 0.0, a: 400.0, b: 400.0, c: 400.0]}}
             )

    assert {:ok, nil} ==
             try_command(
               {nil,
                {:command_movement,
                 [x: 0.0, y: 0.0, z: 10.0, a: 400.0, b: 400.0, c: 400.0]}}
             )
  end

  test "command(), error with tag" do
    assert {:error, _} = @subject.command(firmware_server(), {:x, {:y, :z}})
  end

  test "command(), error no tag" do
    assert {:error, _} = @subject.command(firmware_server(), {:x, :z})
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
