defmodule FarmbotExt.AMQP.LogChannelTest do
  require Helpers

  use ExUnit.Case, async: false
  use Mimic
  setup :verify_on_exit!
  setup :set_mimic_global
  alias FarmbotExt.AMQP.LogChannel
  alias FarmbotExt.AMQP.Support

  test "channel termination" do
    fake_reason = :just_testing
    fake_state = {:fake_state}

    expect(Support, :handle_termination, 1, fn reason, state, name ->
      assert reason == fake_reason
      assert state == fake_state
      assert name == "Log"
      :ok
    end)

    LogChannel.terminate(fake_reason, fake_state)
  end
end
