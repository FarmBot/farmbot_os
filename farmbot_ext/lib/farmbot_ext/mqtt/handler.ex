defmodule FarmbotExt.MQTT.Handler do
  require Logger
  use Tortoise.Handler

  def mqtt_child(token, username) do
    opts = [
      client_id: "change_this_later",
      user_name: username,
      password: token,
      server: {Tortoise.Transport.Tcp, host: 'localhost', port: 1883},
      handler: {FarmbotExt.MQTT.Handler, []},
      subscriptions: [
        {"bot.#{username}.from_clients", 0},
        {"bot.#{username}.ping.#", 0},
        {"bot.#{username}.sync.#", 0},
        {"bot.#{username}.terminal_input", 0}
      ]
    ]

    {Tortoise.Connection, opts}
  end

  def publish(pid, topic, payload) do
    send(pid, {:publish, topic, payload})
  end

  def init(args) do
    {:ok, args}
  end

  def connection(status, state) do
    IO.inspect(status, label: "⛆⛆⛆⛆ CONNECTION ⛆⛆⛆⛆")
    # `status` will be either `:up` or `:down`; you can use this to
    # inform the rest of your system if the connection is currently
    # open or closed; tortoise should be busy reconnecting if you get
    # a `:down`
    {:ok, state}
  end

  def handle_message([_bot, _device, "ping", time], payload, state) do
    IO.inspect({time, payload}, label: "⛆⛆⛆⛆ TODO: PING HANDLER ⛆⛆⛆⛆")
    {:ok, state}
  end

  def handle_message(topic, payl, state) do
    Logger.debug("Unhandled MQTT message: " <> inspect({topic, payl}))
    {:ok, state}
  end

  def subscription(status, topic_filter, state) do
    IO.inspect({status, topic_filter}, label: "⛆⛆⛆⛆ SUBSCRIPTION ⛆⛆⛆⛆")
    {:ok, state}
  end

  def terminate(reason, _state) do
    IO.inspect(reason, label: "⛆⛆⛆⛆ TERMINATED ⛆⛆⛆⛆")
    # tortoise doesn't care about what you return from terminate/2
    :ok
  end
end
