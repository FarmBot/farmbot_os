defmodule FarmbotExt.MQTT.Handler do
  require Logger
  use Tortoise.Handler

  defstruct client_id: "NOT_SET", connection_status: :down

  alias __MODULE__, as: State

  def connection(status, s), do: {:ok, %{s | connection_status: status}}

  def subscription(_stat, _filter, state), do: {:ok, state}

  def init(args) do
    {:ok, %State{client_id: Keyword.fetch!(args, :client_id)}}
  end

  def handle_message([a, b, "ping", d], payload, %State{client_id: id} = s) do
    topic = Enum.join([a, b, "pong", d], "/")
    Tortoise.publish(id, topic, payload, qos: 0)
    {:ok, s}
  end

  def handle_message(topic, payl, state) do
    Logger.debug("⛆⛆⛆⛆ Unhandled MQTT message: " <> inspect({topic, payl}))
    {:ok, state}
  end
end
