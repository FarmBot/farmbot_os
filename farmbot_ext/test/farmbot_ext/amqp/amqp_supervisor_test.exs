defmodule FarmbotExt.AMQP.SupervisorTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotExt.AMQP.Supervisor

  setup :verify_on_exit!

  test "children" do
    results = Supervisor.children()

    # email = System.get_env("FARMBOT_EMAIL")

    expected = [
      {FarmbotExt.AMQP.ConnectionWorker, [token: nil, email: "test@test.com"]},
      {FarmbotExt.AMQP.ChannelSupervisor, [nil]},
      {Tortoise.Connection,
       [
         client_id: "change_this_later",
         user_name: "test@test.com",
         password: nil,
         server: {Tortoise.Transport.Tcp, [host: 'localhost', port: 1883]},
         handler: {FarmbotExt.MQTT.Handler, []},
         subscriptions: [
           {"bot.test@test.com.from_clients", 0},
           {"bot.test@test.com.ping.#", 0},
           {"bot.test@test.com.sync.#", 0},
           {"bot.test@test.com.terminal_input", 0}
         ]
       ]}
    ]

    assert results == expected
  end
end
