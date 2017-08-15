defmodule Farmbot.BotStateTest do
  @moduledoc "Tests the bot state struct and server."

  use ExUnit.Case
  alias Farmbot.BotState
  doctest BotState

  test "subscribes to events" do
    {:ok, pid} = BotState.start_link()
    :ok = BotState.subscribe(pid)
    assert_receive {:bot_state, state}
  end

  test "cant subscribe twice" do
    {:ok, pid} = BotState.start_link()
    first = BotState.subscribe(pid)
    second = BotState.subscribe(pid)
    assert match?(:ok, first)
    assert match?({:error, :already_subscribed}, second)

    task = Task.async(fn() ->
      third = BotState.subscribe(pid)
      assert match?(:ok, third)
    end)

    Task.await(task)
  end

  test "unsubscribes from events" do
    {:ok, pid} = BotState.start_link()
    :ok = BotState.subscribe(pid)

    unsub = BotState.unsubscribe(pid)
    assert unsub == true
  end


  test "updates parts"

  test "forces a dispatch."
end
