defmodule FarmbotExt.AMQP.TerminalChannelSupportTest do
  use ExUnit.Case, async: false
  use Mimic
  setup :verify_on_exit!
  setup :set_mimic_global
  alias FarmbotExt.AMQP.TerminalChannelSupport

  test "tty_send" do
    fake_bot_name = "device_15"
    fake_chan = %{fake: :chan}
    fake_data = "Hello, world!"

    expect(AMQP.Basic, :publish, 1, fn amqp_channel, "amq.topic", bot, data ->
      assert amqp_channel == fake_chan
      assert bot == "bot.device_15.terminal_output"
      assert data == fake_data
    end)

    TerminalChannelSupport.tty_send(fake_bot_name, fake_chan, fake_data)
  end

  test "get_channel - error" do
    expect(FarmbotExt.AMQP.Support, :create_queue, 1, fn name ->
      assert name == "device_15_terminal"
      {:error, "just a test"}
    end)

    result = TerminalChannelSupport.get_channel("device_15")
    assert result == {:error, "just a test"}
  end

  test "get_channel - ok" do
    fake_chan = %{fake: :chan}

    expect(FarmbotExt.AMQP.Support, :create_queue, 1, fn name ->
      assert name == "device_15_terminal"
      {:ok, {%{not: :used}, fake_chan}}
    end)

    expect(AMQP.Queue, :bind, 1, fn chan, name, exchange, opts ->
      assert chan == fake_chan
      assert name == "device_15_terminal"
      assert exchange == "amq.topic"
      assert opts == [routing_key: "bot.device_15.terminal_input"]
      :ok
    end)

    expect(AMQP.Basic, :consume, 1, fn chan, name, pid, opts ->
      assert chan == fake_chan
      assert name == "device_15_terminal"
      assert pid == self()
      assert opts == [no_ack: true]
      {:ok, :not_used}
    end)

    result = TerminalChannelSupport.get_channel("device_15")
    assert result == {:ok, fake_chan}
  end
end
