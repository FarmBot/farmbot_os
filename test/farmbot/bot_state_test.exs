defmodule Farmbot.BotStateTest do
  @moduledoc "Tests the bot state struct and server."

  use ExUnit.Case
  alias Farmbot.BotState
  doctest BotState

  test "subscribes to events" do
    {:ok, pid} = BotState.start_link([])
    :ok = BotState.subscribe(pid)
    assert_receive {:bot_state, _state}
  end

  test "cant subscribe twice" do
    {:ok, pid} = BotState.start_link([])
    first = BotState.subscribe(pid)
    second = BotState.subscribe(pid)
    assert match?(:ok, first)
    assert match?({:error, :already_subscribed}, second)

    task =
      Task.async(fn ->
        third = BotState.subscribe(pid)
        assert match?(:ok, third)
      end)

    Task.await(task)
  end

  test "unsubscribes from events" do
    {:ok, pid} = BotState.start_link([])
    :ok = BotState.subscribe(pid)

    unsub = BotState.unsubscribe(pid)
    assert unsub == true
  end

  test "updates parts" do
    alias BotState.{InformationalSettings, Configuration, LocationData, ProcessInfo}

    {:ok, pid} = BotState.start_link([])
    :ok = GenServer.cast(pid, {:update, InformationalSettings, :info_state})
    :ok = GenServer.cast(pid, {:update, Configuration, :config_state})
    :ok = GenServer.cast(pid, {:update, LocationData, :location_data_state})
    :ok = GenServer.cast(pid, {:update, ProcessInfo, :proc_info_state})

    %{bot_state: state} = :sys.get_state(pid)
    assert state.informational_settings == :info_state
    assert state.configuration == :config_state
    assert state.location_data == :location_data_state
    assert state.process_info == :proc_info_state
  end

  test "forces a dispatch." do
    {:ok, pid} = BotState.start_link([])
    :ok = BotState.subscribe(pid)
    # receive the first on_subscribe message.
    receive do
      {:bot_state, _} -> :ok
    end

    # make sure there is no more messages in the queue
    refute_received {:bot_state, _}

    BotState.force_dispatch(pid)
    assert_received {:bot_state, _state}
  end
end
