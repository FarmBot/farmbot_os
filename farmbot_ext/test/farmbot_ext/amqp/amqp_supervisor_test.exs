defmodule FarmbotExt.AMQP.SupervisorTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotExt.AMQP.Supervisor
  alias FarmbotCore.Config

  setup :verify_on_exit!

  test "children" do
    email = System.get_env("FARMBOT_EMAIL")
    t = Helpers.fake_jwt()

    expect(Config, :get_config_value, 2, fn
      :string, "authorization", "token" -> t
      :string, "authorization", "email" -> email
    end)

    results = Supervisor.children()

    expected = [
      {FarmbotExt.AMQP.ConnectionWorker, [token: t, email: email]},
      {FarmbotExt.AMQP.ChannelSupervisor, [t]},
      {Tortoise.Connection,
       [
         user_name: "device_15",
         password: t,
         server: {Tortoise.Transport.Tcp, [host: "localhost", port: 1883]},
         backoff: [min_interval: 6_000, max_interval: 120_000],
         subscriptions: [
           {"bot.device_15.from_clients", 0},
           {"bot.device_15.ping.#", 0},
           {"bot.device_15.sync.#", 0},
           {"bot.device_15.terminal_input", 0}
         ]
       ]}
    ]

    assert Enum.at(results, 0) == Enum.at(expected, 0)
    assert Enum.at(results, 1) == Enum.at(expected, 1)
    {Tortoise.Connection, actual_mqtt} = Enum.at(results, 2)
    {Tortoise.Connection, expected_mqtt} = Enum.at(expected, 2)

    Enum.map(expected_mqtt, fn
      {key, value} ->
        assert Keyword.fetch!(actual_mqtt, key) == value
    end)
  end
end
