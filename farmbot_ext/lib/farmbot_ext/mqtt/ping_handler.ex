defmodule FarmbotExt.MQTT.PingHandler do
  alias __MODULE__, as: State
  alias FarmbotExt.MQTT
  defstruct client_id: "NOT_SET", last_refresh: 0
  require Logger
  use GenServer
  @refresh_rate 3000

  def start_link(default, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, default, opts)
  end

  def init(opts) do
    {:ok, %State{client_id: Keyword.fetch!(opts, :client_id)}}
  end

  def handle_info({:inbound, [a, b, "ping", d], payload}, state) do
    topic = Enum.join([a, b, "pong", d], "/")
    MQTT.publish(state.client_id, topic, payload)
    now = :os.system_time(:millisecond)
    diff = now - state.last_refresh

    if diff > @refresh_rate do
      # Force the bot to broadcast state tree- someone is
      # using the web app.
      FarmbotExt.MQTT.BotStateChannel.read_status()
      {:noreply, %{state | last_refresh: now}}
    else
      # No one is using the web app. There is no point in
      # broadcasting.
      {:noreply, state}
    end
  end

  def handle_info(_other, state), do: {:noreply, state}
end
