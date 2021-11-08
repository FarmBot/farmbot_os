defmodule FarmbotOS.LogHandlerTest do
  use ExUnit.Case
  use Mimic
  # alias FarmbotOS.MQTT
  alias FarmbotOS.MQTT.{LogHandler, LogHandlerSupport}
  alias FarmbotOS.{BotState, Logger, Log}

  import ExUnit.CaptureLog

  @fake_state %LogHandler{
    client_id: "my_client_id",
    state_cache: nil,
    username: "my_username"
  }

  @fake_args [client_id: "my_client_id", username: "my_username"]

  @fake_log %Log{
    level: :success,
    message: "Unit tests",
    updated_at: ~N[2021-03-26 19:40:49.322695],
    verbosity: 1
  }

  test "start_link" do
    {:ok, pid} = LogHandler.start_link(@fake_args, name: :just_a_test)
    assert is_pid(pid)
    Process.exit(pid, :normal)
  end

  test "init" do
    {:ok, @fake_state, 0} = LogHandler.init(@fake_args)
  end

  test "handle_info(:timeout, state) - no locally cached bot state" do
    expect(BotState, :subscribe, 1, fn -> :fake_bot_state_ng end)
    expected_state = %{@fake_state | state_cache: :fake_bot_state_ng}
    {:noreply, next_state, 0} = LogHandler.handle_info(:timeout, @fake_state)
    assert next_state == expected_state
  end

  test "handle_info(:timeout, state) - ready with cached state" do
    fake_log_queue = [:logs_here]
    expect(Logger, :handle_all_logs, 1, fn -> fake_log_queue end)
    state = %{@fake_state | state_cache: :fake_bot_state_ng}
    result = LogHandler.handle_info(:timeout, state)
    {:noreply, ^state, {:continue, ^fake_log_queue}} = result
  end

  test "handle_info({BotState, change}, state)" do
    expect(Ecto.Changeset, :apply_changes, 1, fn :my_change ->
      :new_state_cache
    end)

    results = LogHandler.handle_info({BotState, :my_change}, @fake_state)
    expected_state = %{@fake_state | state_cache: :new_state_cache}
    assert {:noreply, expected_state, 50} == results
  end

  test "handle_info(misc, state)" do
    go = fn -> LogHandler.handle_info(:something_else, @fake_state) end
    expected_message = "UNEXPECTED MESSAGE: :something_else"
    assert capture_log(go) =~ expected_message
  end

  test "handle_continue([], state)" do
    expected = {:noreply, @fake_state, 50}
    result = LogHandler.handle_continue([], @fake_state)
    assert result == expected
  end

  test "handle_continue([log | rest], state) - OK" do
    log1 = %{@fake_log | message: "1"}
    log2 = %{@fake_log | message: "2"}
    logs = [log1, log2]
    expected = {:noreply, @fake_state, {:continue, [log2]}}

    expect(LogHandlerSupport, :maybe_publish_log, 1, fn log, state ->
      assert log == log1
      assert state == @fake_state
      :ok
    end)

    actual = LogHandler.handle_continue(logs, @fake_state)
    assert expected == actual
  end

  test "handle_continue([log | rest], state) - ERROR" do
    log1 = %{@fake_log | message: "1"}
    logs = [log1]
    expected = {:noreply, @fake_state, 50}

    expect(LogHandlerSupport, :maybe_publish_log, 1, fn log, state ->
      assert log == log1
      assert state == @fake_state
      {:error, "This is a test..."}
    end)

    expect(FarmbotOS.Logger, :insert_log!, 1, fn log ->
      assert log == log1
    end)

    actual = LogHandler.handle_continue(logs, @fake_state)
    assert expected == actual
  end
end
