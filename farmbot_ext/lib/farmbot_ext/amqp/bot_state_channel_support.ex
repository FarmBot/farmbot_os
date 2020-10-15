defmodule FarmbotExt.AMQP.BotStateChannelSupport do
  @exchange "amq.topic"

  alias FarmbotCore.BotStateNG
  alias FarmbotCore.JSON

  def broadcast_state(chan, jwt_dot_bot, cache) do
    json =
      cache
      |> BotStateNG.view()
      |> JSON.encode!()

    AMQP.Basic.publish(chan, @exchange, "bot.#{jwt_dot_bot}.status", json)
  end
end
