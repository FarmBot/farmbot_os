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

  def handle_message([a, b, "ping", d], payload, s) do
    publish(s, Enum.join([a, b, "pong", d], "/"), payload)
    {:ok, s}
  end

  def handle_message(topic, payl, state) do
    Logger.debug("⛆⛆⛆⛆ Unhandled MQTT message: " <> inspect({topic, payl}))
    {:ok, state}
  end

  def publish(state, topic, payload, opts \\ [qos: 0]) do
    if state.connection_status == :up do
      Tortoise.publish(state.client_id, topic, payload, opts)
    else
      Logger.debug("FARMBOT IS OFFLINE, CANT SEND #{topic}")
    end
  end

  def terminate(reason, _state) do
    Logger.debug("MQTT Connection Failed: #{inspect(reason)}")
  end
end
