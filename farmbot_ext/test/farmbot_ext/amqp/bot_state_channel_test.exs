defmodule FarmbotExt.AMQP.BotStateChannelTest do
  require Helpers
  use ExUnit.Case, async: false
  use Mimic

  # alias FarmbotExt.AMQP.BotStateChannel
  # alias FarmbotCore.BotState

  setup :verify_on_exit!
  setup :set_mimic_global

  defmodule FakeState do
    defstruct conn: %{fake: :conn}, chan: "fake_chan_", jwt: "fake_jwt_", cache: %{fake: :cache}
  end

  test "terminate" do
    expect(AMQP.Channel, :close, 1, fn "fake_chan_" -> :ok end)
    Helpers.expect_log("Disconnected from BotState channel: \"foo\"")
    FarmbotExt.AMQP.BotStateChannel.terminate("foo", %FakeState{})
  end
end
