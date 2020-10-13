defmodule FarmbotExt.AMQP.ConnectionWorkerTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias AMQP.Basic
  alias FarmbotExt.AMQP.ConnectionWorker

  test "rpc_reply" do
    fake_jwt_dot_bot = "foo.bar.baz"
    fake_label = "123"
    fake_chan = %{fake: :chan}

    expect(Basic, :publish, 1, fn chan, exchange, queue, json ->
      assert chan == fake_jwt_dot_bot
      assert exchange == "amq.topic"
      assert queue == "bot.123.from_device"
      assert json == "{\"args\":{\"label\":{\"fake\":\"chan\"}},\"kind\":\"rpc_ok\"}"
      :ok
    end)

    ConnectionWorker.rpc_reply(fake_jwt_dot_bot, fake_label, fake_chan)
  end
end
