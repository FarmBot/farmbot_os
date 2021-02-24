defmodule FarmbotExt.MQTT.ConnectionWorker do
  use Tortoise.Handler

  def init(args) do
    IO.inspect(args, label: "=== INIT")
    {:ok, args}
  end

  def connection(status, state) do
    IO.inspect(status, label: "=== CONNECTION")
    # `status` will be either `:up` or `:down`; you can use this to
    # inform the rest of your system if the connection is currently
    # open or closed; tortoise should be busy reconnecting if you get
    # a `:down`
    {:ok, state}
  end

  def handle_message(topic, _payload, state) do
    IO.inspect(topic, label: "===")
    # unhandled message! You will crash if you subscribe to something
    # and you don't have a 'catch all' matcher; crashing on unexpected
    # messages could be a strategy though.
    {:ok, state}
  end

  def subscription(status, topic_filter, state) do
    IO.inspect({status, topic_filter}, label: "=== SUBSCRIPTION")
    {:ok, state}
  end

  def terminate(reason, _state) do
    IO.inspect(reason, label: "=== SUBSCRIPTION")
    # tortoise doesn't care about what you return from terminate/2,
    # that is in alignment with other behaviours that implement a
    # terminate-callback
    :ok
  end
end
