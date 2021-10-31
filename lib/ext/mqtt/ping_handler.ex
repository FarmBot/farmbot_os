defmodule FarmbotOS.MQTT.PingHandler do
  alias __MODULE__, as: State

  alias FarmbotOS.{
    MQTT,
    Time
  }

  defstruct client_id: "NOT_SET", last_refresh: 0
  require Logger
  use GenServer
  @refresh_rate 3000
  @ping "ping"
  @pong "pong"

  def start_link(default, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, default, opts)
  end

  def init(opts) do
    {:ok, %State{client_id: Keyword.fetch!(opts, :client_id)}}
  end

  def handle_info({:inbound, [_, _, @ping, _] = t, payload}, state) do
    MQTT.publish(state.client_id, create_reply_topic(t), payload)
    now = Time.system_time_ms()
    diff = now - state.last_refresh

    if diff > @refresh_rate do
      # Force the bot to broadcast state tree- someone is
      # using the web app.
      FarmbotOS.MQTT.BotStateHandler.read_status()
      {:noreply, %{state | last_refresh: now}}
    else
      # No one is using the web app. There is no point in
      # broadcasting.
      {:noreply, state}
    end
  end

  def handle_info(_other, state), do: {:noreply, state}

  def create_reply_topic([a, b, _ping, d]), do: Enum.join([a, b, @pong, d], "/")
end
