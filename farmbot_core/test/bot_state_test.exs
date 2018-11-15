defmodule Farmbot.BotStateTest do
  use ExUnit.Case
  alias Farmbot.BotState

  describe "bot state pub/sub" do
    test "subscribes to bot state updates" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      _initial_state = BotState.subscribe(bot_state_pid)
      :ok = BotState.set_user_env(bot_state_pid, "some_key", "some_val")
      assert_receive {BotState, %Ecto.Changeset{valid?: true}}
    end

    test "invalid data doesn't get dispatched" do
      {:ok, bot_state_pid} = BotState.start_link([], [])
      _initial_state = BotState.subscribe(bot_state_pid)
      result = BotState.report_disk_usage(bot_state_pid, "this is invalid")
      assert match?({:error, %Ecto.Changeset{valid?: false}}, result)
      refute_receive {BotState, %Ecto.Changeset{valid?: true}}
    end

    test "subscribing links current process" do
      # Trap exits so we can assure we can see bot the
      # BotState processess and the subscriber process crash.
      Process.flag(:trap_exit, true)

      # two links, BotState and Subscriber
      {:ok, bot_state_pid} = BotState.start_link([], [])

      fun = fn ->
        _initial_state = BotState.subscribe(bot_state_pid)
        exit(:crash)
      end

      # Spawn the subscriber function
      fun_pid = spawn_link(fun)

      # Make sure both BotState and Subscriber crashes
      assert_receive {:EXIT, ^fun_pid, :crash}
      assert_receive {:EXIT, ^bot_state_pid, :crash}
    end
  end
end
