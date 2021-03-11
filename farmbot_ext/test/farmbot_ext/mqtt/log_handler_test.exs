defmodule FarmbotExt.LogHandlerTest do
  use ExUnit.Case
  use Mimic
  # alias FarmbotExt.MQTT
  alias FarmbotExt.MQTT.LogHandler
  alias FarmbotCore.{BotState, Logger}
  import ExUnit.CaptureLog

  @fake_state %LogHandler{
    client_id: "my_client_id",
    state_cache: nil,
    username: "my_username"
  }

  @fake_args [client_id: "my_client_id", username: "my_username"]

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
end
