defmodule FarmbotExt.AMQP.BotStateChannelSupportTest do
  require Helpers

  use ExUnit.Case, async: false
  use Mimic

  setup :verify_on_exit!
  alias FarmbotExt.AMQP.BotStateChannelSupport

  test "broadcast_state(chan, jwt_dot_bot, cache)" do
    fake_chan = %{fake: :chan}
    fake_bot = "xyz"
    fake_cache = %{}
    fake_bot_state = %{fake: "bot_state"}

    expect(FarmbotCore.BotStateNG, :view, 1, fn view ->
      assert view == fake_cache
      fake_bot_state
    end)

    expect(AMQP.Basic, :publish, 1, fn chan, xchng, rte, json ->
      assert chan == fake_chan
      assert xchng == "amq.topic"
      assert rte == "bot.xyz.status"
      assert json == "{\"fake\":\"bot_state\"}"
      :ok
    end)

    results = BotStateChannelSupport.broadcast_state(fake_chan, fake_bot, fake_cache)
    assert :ok == results
  end
end
