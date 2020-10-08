defmodule FarmbotExt.AMQP.CeleryScriptChannelTest do
  require Helpers
  use ExUnit.Case, async: false
  use Mimic

  setup :verify_on_exit!
  setup :set_mimic_global

  defmodule FakeState do
    defstruct conn: %{fake: :conn}, chan: "fake_chan_", jwt: "fake_jwt_", cache: %{fake: :cache}
  end

  test "terminate" do
    expect(AMQP.Channel, :close, 1, fn "fake_chan_" -> :ok end)
    Helpers.expect_log("Disconnected from CeleryScript channel: \"foo\"")

    FarmbotExt.AMQP.CeleryScriptChannel.terminate("foo", %FakeState{})
  end
end
