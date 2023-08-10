defmodule FarmbotOS.BotStateTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.{BotState, BotStateNG}
  alias FarmbotOS.BotState.JobProgress.Percent

  describe "bot state pub/sub" do
    test "subscribes to bot state updates" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      _initial_state = BotState.subscribe(bot_state_pid)
      :ok = BotState.set_user_env(bot_state_pid, "some_key", "some_val")
      assert_receive {BotState, %Ecto.Changeset{valid?: true}}
    end

    @tag :capture_log
    test "invalid data doesn't get dispatched" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      _initial_state = BotState.subscribe(bot_state_pid)
      result = BotState.report_disk_usage(bot_state_pid, "this is invalid")
      assert match?({:error, %Ecto.Changeset{valid?: false}}, result)
      refute_receive {BotState, %Ecto.Changeset{valid?: true}}
    end
  end

  describe "pins" do
    test "sets pin data" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      :ok = BotState.set_pin_value(bot_state_pid, 9, 1, 0)
      :ok = BotState.set_pin_value(bot_state_pid, 10, 1, 0)
      :ok = BotState.set_pin_value(bot_state_pid, 11, 0, 0)

      assert %{pins: %{9 => %{value: 1}, 10 => %{value: 1}, 11 => %{value: 0}}} =
               BotState.fetch(bot_state_pid)
    end
  end

  describe "updates bot state" do
    test "updates informational_settings" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      :ok = BotState.set_firmware_unlocked(bot_state_pid)
      :ok = BotState.set_firmware_version(bot_state_pid, "0.0.0")
      :ok = BotState.set_firmware_hardware(bot_state_pid, "arduino")
      :ok = BotState.set_sync_status(bot_state_pid, "synced")
      :ok = BotState.set_node_name(bot_state_pid, "0000")
      :ok = BotState.set_private_ip(bot_state_pid, "0.0.0.0")
      :ok = BotState.report_memory_usage(bot_state_pid, 250)
      :ok = BotState.report_soc_temp(bot_state_pid, 40)
      :ok = BotState.report_throttled(bot_state_pid, "0x0")
      :ok = BotState.report_uptime(bot_state_pid, 1000)
      :ok = BotState.report_wifi_level(bot_state_pid, -50)
      :ok = BotState.report_wifi_level_percent(bot_state_pid, 100)
      :ok = BotState.report_video_devices(bot_state_pid, "1,0")

      assert %{
               informational_settings: %{
                 locked: false,
                 firmware_version: "0.0.0",
                 sync_status: "synced",
                 node_name: "0000",
                 private_ip: "0.0.0.0",
                 memory_usage: 250,
                 soc_temp: 40,
                 throttled: "0x0",
                 uptime: 1000,
                 wifi_level: -50,
                 wifi_level_percent: 100,
                 video_devices: "1,0"
               }
             } = BotState.fetch(bot_state_pid)
    end

    test "sets locked" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      :ok = BotState.set_firmware_locked(bot_state_pid)

      assert %{informational_settings: %{locked: true}} =
               BotState.fetch(bot_state_pid)
    end

    test "updates configuration" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      :ok = BotState.set_firmware_hardware(bot_state_pid, "arduino")

      assert %{configuration: %{firmware_hardware: "arduino"}} =
               BotState.fetch(bot_state_pid)
    end

    test "updates mcu_params" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      :ok = BotState.set_firmware_config(bot_state_pid, "encoder_invert_x", 1)

      assert %{mcu_params: %{encoder_invert_x: 1.0}} =
               BotState.fetch(bot_state_pid)
    end

    test "updates location_data" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      :ok = BotState.set_position(bot_state_pid, 1, 2, 3)
      :ok = BotState.set_load(bot_state_pid, 100, 100, 100)
      :ok = BotState.set_encoders_scaled(bot_state_pid, 1, 2, 3)
      :ok = BotState.set_encoders_raw(bot_state_pid, 10, 20, 30)

      assert %{
               location_data: %{
                 position: %{x: 1.0, y: 2.0, z: 3.0},
                 load: %{x: 100.0, y: 100.0, z: 100.0},
                 scaled_encoders: %{x: 1.0, y: 2.0, z: 3.0},
                 raw_encoders: %{x: 10.0, y: 20.0, z: 30.0}
               }
             } = BotState.fetch(bot_state_pid)
    end
  end

  test "set_job_progress" do
    {:ok, bot_state_pid} = BotState.start_link([], [])
    _old_state = BotState.subscribe(bot_state_pid)

    prog = %Percent{
      status: "Working",
      percent: 50
    }

    :ok = BotState.set_job_progress(bot_state_pid, "test123", prog)

    receive do
      {BotState, cs} ->
        prog1 = Map.from_struct(prog)
        prog2 = Map.fetch!(cs.changes.jobs, "test123")
        assert prog1.file_type == nil
        assert prog1.percent == 50
        assert prog1.status == "Working"
        assert prog1.time == nil
        assert prog1.type == ""
        assert prog1.unit == "percent"
        assert is_number(prog2.updated_at)
    after
      5000 ->
        refute "Timeout has elapsed"
    end
  end

  @empty_state %{
    tree: BotStateNG.new(),
    subscribers: []
  }

  test "set_firmware_locked - on" do
    fake_time = 123
    expect(FarmbotOS.Time, :system_time_ms, 1, fn -> fake_time end)

    {:reply, :ok, state} =
      BotState.handle_call({:set_firmware_locked, true}, nil, @empty_state)

    assert state.tree.informational_settings.locked
    assert state.tree.informational_settings.locked_at == 123
  end

  test "handle_call({:report_uptime, seconds}, _form, state)" do
    {:reply, :ok, next_state} =
      FarmbotOS.BotState.handle_call({:report_uptime, 123}, nil, @empty_state)

    assert next_state.tree.informational_settings.uptime == 123
  end
end
