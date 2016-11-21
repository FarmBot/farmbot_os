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
    Logger.debug "MQTT Connected"
    GenMQTT.subscribe(self(), bot_topic(token), 0)
    Farmbot.Sync.sync
    Logger.debug "MQTT Subscribed"
    {:ok, token}
  end

  def on_publish(["bot", bot, "from_clients"], msg, %Token{} = token) do
    with true <- bot == token.unencoded.bot,
    do:
      msg
      |> Poison.decode!
      |> RPC.MessageManager.sync_notify
      Logger.debug("Got message: #{inspect msg}")
      {:ok, token}
  end

  def handle_cast(something, state) do
    Logger.debug("CAST: #{inspect something}")
    {:noreply, state}
  end

  def handle_info({:emit, binary}, %Token{} = token) do
    GenMQTT.publish(self(), frontend_topic(token), binary, 1, false)
    {:noreply, token}
  end

  def handle_info(something, state) do
    Logger.debug("INFO: #{inspect something}")
    {:noreply, state}
  end

  # this is not a erronous situation, so don't alert.
  def terminate(:new_token, _) do
    Logger.warn("Get a new token. MQTT Going down.")
    :ok
  end

  @spec build_opts(Token.t) :: GenMQTT.option
  defp build_opts(%Token{} = token) do
    [name: __MODULE__,
     host: token.unencoded.mqtt,
     password: token.encoded,
     username: token.unencoded.bot]
     # these dont work for some reason
    #  last_will_topic: frontend_topic(token),
    #  last_will_message: build_last_will_message]
  end

  @spec frontend_topic(Token.t) :: String.t
  defp frontend_topic(%Token{} = token), do: "bot/#{token.unencoded.bot}/from_device"

  @spec bot_topic(Token.t) :: String.t
  defp bot_topic(%Token{} = token), do: "bot/#{token.unencoded.bot}/from_clients"


  defp build_last_will_message do
    msg = Farmbot.RPC.Handler.log_msg("Bot going offline",
                                       [:error_ticker],
                                       ["ERROR"])
    IO.inspect msg
    msg
  end
end
