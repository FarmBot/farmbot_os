defmodule FarmbotExt.MQTT.PingHandler do
  alias __MODULE__, as: State
  alias FarmbotExt.MQTT
  defstruct client_id: "NOT_SET"
  require Logger
  use GenServer

  def start_link(default, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, default, opts)
  end

  def init(opts) do
    {:ok, %State{client_id: Keyword.fetch!(opts, :client_id)}}
  end

  def handle_info({:inbound, [a, b, "ping", d], payload}, state) do
    topic = Enum.join([a, b, "pong", d], "/")
    MQTT.publish(state.client_id, topic, payload)
    {:noreply, state}
  end

  def handle_info(_other, state), do: {:noreply, state}
end
