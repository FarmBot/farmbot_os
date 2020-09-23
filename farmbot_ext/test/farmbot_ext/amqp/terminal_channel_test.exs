defmodule FarmbotExt.AMQP.TerminalChannelTest do
  use ExUnit.Case, async: false
  use Mimic
  setup :verify_on_exit!
  setup :set_mimic_global
  alias FarmbotExt.AMQP.TerminalChannel
  alias FarmbotExt.AMQP.TerminalChannelSupport, as: Support

  @jwt %FarmbotExt.JWT{bot: "device_#{Enum.random(1000..100_000)}"}
  @chan %{fake_chan: true}

  def expect_log(msg) do
    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      assert log.message == msg
    end)
  end

  # Simulates a series of network return values for a stubbed
  # version of TerminalChannelSupport.get_channel/1
  def simulate_network(return_values) do
    total = Enum.count(return_values)
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    expect(Support, :get_channel, total, fn bot ->
      current_index = Agent.get(agent, fn list -> list end)
      Agent.update(agent, fn count -> count + 1 end)
      next_value = Enum.at(return_values, current_index)
      assert bot == @jwt.bot
      next_value
    end)
  end

  test "terminal channel startup" do
    expect_log("Connected to terminal channel")
    simulate_network([{:ok, @chan}])
    {:ok, pid} = TerminalChannel.start_link([jwt: @jwt], [])
    actual = :sys.get_state(pid)
    expected = %TerminalChannel{chan: @chan, iex_pid: nil, jwt: @jwt}
    assert actual == expected
    GenServer.stop(pid, :normal)
  end

  test "terminal channel startup - nil return value" do
    expect_log("Connected to terminal channel")

    simulate_network([nil, {:ok, @chan}])

    {:ok, pid} = TerminalChannel.start_link([jwt: @jwt], [])
    actual = :sys.get_state(pid)
    expected = %TerminalChannel{chan: @chan, iex_pid: nil, jwt: @jwt}
    assert actual == expected
    GenServer.stop(pid, :normal)
  end

  test "terminal channel startup - return an error" do
    expect_log("Terminal connection failed: {:error, \"Try again\"}")
    simulate_network([{:error, "Try again"}, {:ok, @chan}])

    {:ok, pid} = TerminalChannel.start_link([jwt: @jwt], [])
    actual = :sys.get_state(pid)
    expected = %TerminalChannel{chan: @chan, iex_pid: nil, jwt: @jwt}
    assert actual == expected
    GenServer.stop(pid, :normal)
  end
end
