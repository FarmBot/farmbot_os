defmodule FarmbotExt.AMQP.PingPongChannelTest do
  require Helpers

  use ExUnit.Case, async: false
  use Mimic
  setup :verify_on_exit!
  setup :set_mimic_global
  alias FarmbotExt.AMQP.PingPongChannel
  alias FarmbotExt.AMQP.Support
  alias FarmbotCore.Leds

  test "channel termination" do
    fake_reason = :just_testing
    fake_state = {:fake_state}

    expect(Leds, :blue, 1, fn state ->
      assert state == :off
      :ok
    end)

    expect(Support, :handle_termination, 1, fn reason, state, name ->
      assert reason == fake_reason
      assert state == fake_state
      assert name == "PingPong"
      :ok
    end)

    PingPongChannel.terminate(fake_reason, fake_state)
  end

  test "do_connect/2" do
    Helpers.expect_log("connected to PingPong channel")
    result = PingPongChannel.do_connect({:ok, {:conn123, :chan123}}, %{chan: 1, conn: 2})
    {:noreply, %{conn: conn, chan: chan}} = result
    assert conn == :conn123
    assert chan == :chan123
  end
end
