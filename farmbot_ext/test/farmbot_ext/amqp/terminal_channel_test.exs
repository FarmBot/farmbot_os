defmodule FarmbotExt.AMQP.TerminalChannelTest do
  require Helpers

  use ExUnit.Case, async: false
  use Mimic
  setup :verify_on_exit!
  setup :set_mimic_global
  alias FarmbotExt.AMQP.TerminalChannel
  alias FarmbotExt.AMQP.TerminalChannelSupport, as: Support

  @jwt %FarmbotExt.JWT{bot: "device_#{Enum.random(1000..100_000)}"}
  @chan %{fake_chan: true}

  def tty_send(pid, data) do
    mesg = {:basic_deliver, data, %{routing_key: "UNIT_TESTS"}}
    send(pid, mesg)
    pid
  end

  def base_case() do
    simulate_network([{:ok, @chan}])
    {:ok, pid} = TerminalChannel.start_link([jwt: @jwt], [])
    pid
  end

  # Simulates a series of network return values for a stubbed
  # version of TerminalChannelSupport.get_channel/1
  def expect_response(expectations) do
    total = Enum.count(expectations)
    {:ok, counter} = SimpleCounter.new()

    expect(Support, :tty_send, total, fn _, _, actual ->
      current_index = SimpleCounter.bump(counter, 1) - 1
      expected = Enum.at(expectations, current_index)
      assert expected == actual
      :ok
    end)
  end

  # Simulates a series of network return values for a stubbed
  # version of TerminalChannelSupport.get_channel/1
  def simulate_network(return_values) do
    total = Enum.count(return_values)
    {:ok, counter} = SimpleCounter.new()

    expect(Support, :get_channel, total, fn bot ->
      current_index = SimpleCounter.bump(counter, 1) - 1
      next_value = Enum.at(return_values, current_index)
      assert bot == @jwt.bot
      next_value
    end)
  end

  test "terminal channel startup" do
    Helpers.expect_log("Connected to terminal channel")
    pid = base_case()
    actual = :sys.get_state(pid)
    expected = %TerminalChannel{chan: @chan, iex_pid: nil, jwt: @jwt}
    assert actual == expected
    GenServer.stop(pid, :normal)
  end

  test "terminal channel startup - nil return value" do
    Helpers.expect_log("Connected to terminal channel")

    simulate_network([nil, {:ok, @chan}])

    {:ok, pid} = TerminalChannel.start_link([jwt: @jwt], [])
    actual = :sys.get_state(pid)
    expected = %TerminalChannel{chan: @chan, iex_pid: nil, jwt: @jwt}
    assert actual == expected
    GenServer.stop(pid, :normal)
  end

  test "terminal channel startup - return an error" do
    Helpers.expect_log("Terminal connection failed: {:error, \"Try again\"}")
    simulate_network([{:error, "Try again"}, {:ok, @chan}])

    {:ok, pid} = TerminalChannel.start_link([jwt: @jwt], [])
    actual = :sys.get_state(pid)
    expected = %TerminalChannel{chan: @chan, iex_pid: nil, jwt: @jwt}
    assert actual == expected
    GenServer.stop(pid, :normal)
  end

  test "Connects to AMQP" do
    Helpers.expect_log("Connected to terminal channel")
    pid = base_case()
    previous_state = :sys.get_state(pid)
    messages = [{:basic_cancel_ok, %{}}, {:basic_consume_ok, %{}}]
    Enum.map(messages, fn item -> send(pid, item) end)
    assert previous_state == :sys.get_state(pid)
    send(pid, {:basic_cancel, %{}})
    Process.sleep(1)
    refute Process.alive?(pid)
  end

  test "execute commands over TermincalChannel" do
    expected = [
      "Starting IEx...",
      "Interactive Elixir (1.9.0) - press Ctrl+C to exit (type h() ENTER for help)\r\n",
      "iex(1)> "
    ]

    expect(Support, :tty_send, 4, fn _bot, _chan, actual ->
      assert Enum.member?(expected, actual)
    end)

    tty_send(base_case(), "\r")
    Process.sleep(50)
    tty_send(base_case(), "2 + 2\r")
    Process.sleep(50)
  end
end
