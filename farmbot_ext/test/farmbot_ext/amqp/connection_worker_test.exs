defmodule FarmbotExt.AMQP.ConnectionWorkerTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias AMQP.Basic
  alias FarmbotExt.AMQP.ConnectionWorker

  test "open_connection/5" do
    token = "token123"
    email = "email123"
    bot = "bot123"
    mqtt_server = "mqtt_server123"
    vhost = "vhost123"

    expected_props = [
      "bot",
      "commit",
      "email",
      "node",
      "opened",
      "product",
      "target",
      "version"
    ]

    expect(AMQP.Connection, :open, 1, fn opts ->
      assert Keyword.fetch!(opts, :host) == "mqtt_server123"
      assert Keyword.fetch!(opts, :username) == "bot123"
      assert Keyword.fetch!(opts, :password) == "token123"
      assert Keyword.fetch!(opts, :virtual_host) == "vhost123"
      assert Keyword.fetch!(opts, :connection_timeout) == 10000

      props =
        Keyword.fetch!(opts, :client_properties)
        |> Enum.map(fn
          {key, :longstr, _value} -> key
          wrong -> "WRONG!: #{inspect(wrong)}"
        end)
        |> Enum.sort()

      assert props == expected_props

      :ok
    end)

    ConnectionWorker.open_connection(token, email, bot, mqtt_server, vhost)
  end

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
