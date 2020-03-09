defmodule FarmbotExt.AMQP.BotStateChannelTest do
  use ExUnit.Case
  use Mimic

  # alias FarmbotExt.AMQP.BotStateChannel
  # alias FarmbotCore.BotState

  setup :verify_on_exit!
  setup :set_mimic_global

  defmodule FakeState do
    defstruct conn: %{fake: :conn}, chan: "fake_chan_", jwt: "fake_jwt_", cache: %{fake: :cache}
  end

  test "terminate" do
    expected = "Disconnected from BotState channel: \"foo\""
    expect(AMQP.Channel, :close, 1, fn "fake_chan_" -> :ok end)

    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      assert log.message == expected
    end)

    FarmbotExt.AMQP.BotStateChannel.terminate("foo", %FakeState{})
  end
end
