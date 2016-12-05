defmodule Farmbot.LoggerTest do
  use ExUnit.Case, async: true
  setup_all do
    {:ok, pid} = Farmbot.Logger.start_link []
    {:ok, %{pid: pid}}
  end

  test "logs some stuff" do
    # Log something here("hey world, sup?", [], [])
    msgs = Farmbot.Logger.get_all
    assert Enum.count(msgs) > 0
  end

  test "gets exactly 1 message", context do
    # Log something here("hello", [], [])
    # Log something here("wonderful", [], [])
    # Log something here("world", [], [])
    pid = context[:pid]
    msgs = GenServer.call(pid, {:get, 1})
    assert Enum.count(msgs) == 1
  end

  test "clears the logs" do
    # Log something here("goodbye", [], [])
    # Log something here("cruel", [], [])
    # Log something here("world", [], [])
    msgs = Farmbot.Logger.get_all
    assert Enum.count(msgs) >= 3
    Farmbot.Logger.clear
    no_msgs = Farmbot.Logger.get_all
    assert no_msgs == []
  end
end
