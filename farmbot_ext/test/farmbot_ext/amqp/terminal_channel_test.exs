defmodule FarmbotExt.AMQP.TerminalChannelTest do
  use ExUnit.Case, async: false
  use Mimic
  setup :verify_on_exit!
  setup :set_mimic_global
  alias FarmbotExt.AMQP.TerminalChannel
  alias FarmbotExt.AMQP.TerminalChannelSupport, as: Support

  test "terminal channel startup" do
    jwt = %FarmbotExt.JWT{bot: "device_#{Enum.random(1000..100_000)}"}
    chan = %{fake_chan: true}

    expect(Support, :get_channel, 1, fn bot ->
      assert bot == jwt.bot
      {:ok, chan}
    end)

    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      assert log.message == "Connected to terminal channel"
    end)

    {:ok, pid} = TerminalChannel.start_link([jwt: jwt], [])
    actual = :sys.get_state(pid)
    expected = %TerminalChannel{chan: chan, iex_pid: nil, jwt: jwt}
    assert actual == expected
    GenServer.stop(pid, :normal)
  end
end
