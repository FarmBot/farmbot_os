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

  test "set_job_progress" do
    {:ok, bot_state_pid} = BotState.start_link([], [])
    _old_state = BotState.subscribe(bot_state_pid)

    prog = %Percent{
      status: "working",
      percent: 50
    }

    :ok = BotState.set_job_progress(bot_state_pid, "test123", prog)

    receive do
      {BotState, cs} ->
        prog1 = Map.from_struct(prog)
        prog2 = Map.fetch!(cs.changes.jobs, "test123")
        assert prog1.file_type == nil
        assert prog1.percent == 50
        assert prog1.status == "working"
        assert prog1.time == nil
        assert prog1.type == "ota"
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
