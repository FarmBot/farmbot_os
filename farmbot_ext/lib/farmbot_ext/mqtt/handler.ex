defmodule FarmbotExt.MQTT.Handler do
  alias FarmbotExt.JWT
  require Logger
  use Tortoise.Handler

  @wss "wss:"

  def mqtt_child(raw_token) do
    token = JWT.decode!(raw_token)
    host = token.mqtt
    username = token.bot

    server =
      if String.starts_with?(token.mqtt_ws, @wss) do
        IO.puts("⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆")
        IO.puts("⛆                                                         ⛆")
        IO.puts("⛆   SSL  NOT  ACTUALLY  ENABLED.                          ⛆")
        IO.puts("⛆      FIX  BEFORE  RELEASE!!!                            ⛆")
        IO.puts("⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆   ⛆")

        {Tortoise.Transport.SSL,
         cacertfile: :certifi.cacertfile(), host: host, port: 8883, verify: :verify_none}
      else
        {Tortoise.Transport.Tcp, host: host, port: 1883}
      end

    opts = [
      client_id: "change_this_later",
      user_name: username,
      password: raw_token,
      server: server,
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

  def connection(_status, state) do
    IO.inspect(state, label: "⛆⛆⛆⛆ CONNECTION ⛆⛆⛆⛆")
    # `status` will be either `:up` or `:down`; you can use this to
    # inform the rest of your system if the connection is currently
    # open or closed; tortoise should be busy reconnecting if you get
    # a `:down`
    {:ok, state}
  end

  def handle_message([a, b, "ping", d], payload, state) do
    topic = Enum.join([a, b, "pong", d], "/")
    Tortoise.publish("change_this_later", topic, payload, qos: 0)
    IO.inspect({topic, payload}, label: "⛆⛆⛆⛆ !PONG! ⛆⛆⛆⛆")
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
