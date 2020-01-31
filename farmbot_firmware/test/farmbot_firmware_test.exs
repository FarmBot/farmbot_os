defmodule FarmbotFirmwareTest do
  use ExUnit.Case
  doctest FarmbotFirmware

  def try_command(pid, cmd) do
    GenServer.call(pid, cmd, :infinity)
  end

  def firmware_server do
    arg = [transport: FarmbotFirmware.StubTransport]
    {:ok, pid} = FarmbotFirmware.start_link(arg, [])
    send(pid, :timeout)
    try_command(pid, {nil, {:command_emergency_lock, []}})
    try_command(pid, {nil, {:command_emergency_unlock, []}})
    pid
  end

  test "various command()s" do
    pid = firmware_server()

    cmds = [
      # TEST VALUES EXTRACTED FROM A REAL BOT
      # They may change over time, so a test failure
      # is  not necessarily indicitive of a defect,
      # but it *IS* indicitve of a change (perhaps unepxected?)
      # in runtime behavior.
      #
      # Approach with caution.
      {:pin_mode_write, [p: 13, m: 1]},
      {"1", {:position_write_zero, [:x]}},
      {"23", {:parameter_write, [movement_invert_2_endpoints_y: 1.0]}},
      {"24", {:parameter_write, [movement_stop_at_home_x: 0.0]}},
      {"40", {:pin_write, [p: 13, v: 0, m: 0]}},
      {"49", {:pin_mode_write, [p: 13, m: 1]}},
      {"55", {:pin_mode_write, [p: 13, m: 1]}},
      {"59", {:pin_mode_write, [p: 13, m: 1]}},
      {"94", {:parameter_write, [movement_home_up_y: 1.0]}},
      {"94", {:pin_write, [p: 13, v: 1, m: 0]}},
      {"98", {:parameter_write, [movement_home_up_y: 0.0]}},
      {"99", {:parameter_write, [movement_stop_at_home_x: 1.0]}},
      {nil, {:command_emergency_lock, []}},
      {nil, {:command_emergency_lock, []}},
      {nil,
       {:command_movement,
        [x: 0.0, y: 0.0, z: 0.0, a: 400.0, b: 400.0, c: 400.0]}},
      {nil,
       {:command_movement,
        [x: 0.0, y: 0.0, z: 10.0, a: 400.0, b: 400.0, c: 400.0]}},
      {nil, {:command_emergency_lock, []}}
    ]

    Enum.map(cmds, fn {tag, cmd} ->
      assert {:ok, tag} = try_command(pid, {tag, cmd})
    end)
  end
end
