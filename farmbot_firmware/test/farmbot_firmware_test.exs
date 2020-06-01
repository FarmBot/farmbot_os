defmodule FarmbotFirmwareTest do
  use ExUnit.Case
  doctest FarmbotFirmware

  def try_command(pid, cmd) do
    GenServer.call(pid, cmd, :infinity)
  end

  def try_cast(pid, cmd) do
    GenServer.cast(pid, cmd)
  end

  def firmware_server do
    arg = [reset: StubReset]
    {:ok, pid} = FarmbotFirmware.start_link(arg, [])
    send(pid, :timeout)
    try_command(pid, {nil, {:command_emergency_lock, []}})
    try_command(pid, {nil, {:command_emergency_unlock, []}})
    pid
  end

  @tag :capture_log
  test "various reports" do
    pid = firmware_server()

    reports = [
      {:report_begin, []},
      {:report_busy, []},
      {:report_emergency_lock, []},
      {:report_error, [:calibration_error]},
      {:report_error, [:emergency_lock]},
      {:report_error, [:invalid_command]},
      {:report_error, [:no_config]},
      {:report_error, [:no_error]},
      {:report_error, [:other]},
      {:report_error, [:stall_detected]},
      {:report_error, [:stall_detected_x]},
      {:report_error, [:stall_detected_y]},
      {:report_error, [:stall_detected_z]},
      {:report_error, [:timeout]},
      {:report_error, []},
      {:report_home_complete, [:x]},
      {:report_invalid, []},
      {:report_load, 23.0},
      {:report_retry, []},
      {:report_success, []},
      {:report_axis_timeout, [:x]},
      {:report_debug_message, ["Hello"]},
      {:report_axis_state, [x: :idle]},
      {:report_encoders_raw, [x: 1.4, y: 2.3, z: 3.2]},
      {:report_encoders_scaled, [{:x, 100.0}, {:y, 200.0}, {:z, 400.0}]},
      {:report_end_stops, [xa: 1, xb: 2, ya: 3, yb: 4, za: 5, zb: 6]},
      {:report_parameter_value, [{:param_version, 1.2}]},
      {:report_pin_value, [{:p, 1}, {:v, 2}, {:m, 0}, {:q, 3}]},
      {:report_position_change, [{:x, 200.0}]},
      {:report_position, [x: 1.4, y: 2.3, z: 3.2, s: 4.1]},
      {:report_software_version, ["6.5.0.G"]}
    ]

    Enum.map(reports, fn report ->
      assert :ok = try_cast(pid, {:x, report})
    end)

    Process.sleep(1000)
  end

  @tag :capture_log
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
      {:command_movement,
       [x: 0.0, y: 0.0, z: 0.0, a: 400.0, b: 400.0, c: 400.0]},
      {:command_movement,
       [x: 0.0, y: 0.0, z: 10.0, a: 400.0, b: 400.0, c: 400.0]},
      {:parameter_write, [movement_home_up_y: 0.0]},
      {:parameter_write, [movement_home_up_y: 1.0]},
      {:parameter_write, [movement_invert_2_endpoints_y: 1.0]},
      {:parameter_write, [movement_stop_at_home_x: 0.0]},
      {:parameter_write, [movement_stop_at_home_x: 1.0]},
      {:pin_mode_write, [p: 13, m: 1]},
      {:pin_write, [p: 13, v: 0, m: 0]},
      {:pin_write, [p: 13, v: 1, m: 0]},
      {:position_write_zero, [:x]}
      # {:command_emergency_lock, []},
    ]

    Enum.map(cmds, fn cmd ->
      assert {:ok, "2"} = try_command(pid, {"2", cmd})
    end)
  end
end
