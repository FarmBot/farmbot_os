defmodule Farmbot.RPC.Transport.GenMqtt.Client do
  @moduledoc """
    Experimental mqtt transport.
  """
  use GenMQTT
  require Logger
  def init(%Token{} = token) do
    {:ok, token}
  end

  def start_link(%Token{} = token) do
    GenMQTT.start_link(__MODULE__, token, build_opts(token))
  end

  def on_connect(%Token{} = token) do
    Logger.warn("MQTT CONNECTED")
    GenMQTT.subscribe(self(), bot_topic(token), 0)
    Farmbot.Sync.sync
    {:ok, token}
  end

  def handle_cast({:emit, binary}, %Token{} = token) do
    Logger.debug("hey")
    GenMQTT.publish(self(), frontend_topic(token), binary, 1)
    {:noreply, token}
  end

  # this is not a erronous situation, so don't alert.
  def terminate(:new_token, _) do
    Logger.warn("Get a new token. MQTT Going down.")
    :ok
  end

  defp build_opts(%Token{} = token) do
    [name: __MODULE__,
     host: token.unencoded.mqtt,
     password: token.encoded,
     username: token.unencoded. bot]
  end

  defp frontend_topic(%Token{} = token) do
    "bot/#{token.unencoded.bot}/from_device"
  end

  defp bot_topic(%Token{} = token) do
    "bot/#{token.unencoded.bot}/from_clients"
  end
end
