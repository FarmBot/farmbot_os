defmodule Farmbot.RPC.Transport.GenMqtt.Client do

  @moduledoc """
    MQTT transport for farmbot RPC Commands.
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
    GenMQTT.subscribe(self(), bot_topic(token), 0)
    Logger.debug "Bot is up and running!"
    {:ok, token}
  end

  def on_publish(["bot", bot, "from_clients"], msg, %Token{} = token) do
    with true <- bot == token.unencoded.bot,
    do:
      msg
      |> Poison.decode!
      |> RPC.MessageManager.sync_notify
      {:ok, token}
  end

  def handle_info({:emit, binary}, %Token{} = token) do
    GenMQTT.publish(self(), frontend_topic(token), binary, 1, false)
    {:noreply, token}
  end

  # this is not a erronous situation, so don't alert.
  def terminate(:new_token, _) do
    :ok
  end

  def terminate(reason, _) do
    Logger.error ">>`s mqtt client died. #{inspect reason}"
    :ok
  end

  @spec build_opts(Token.t) :: GenMQTT.option
  defp build_opts(%Token{} = token) do
    [name: __MODULE__,
     host: token.unencoded.mqtt,
     password: token.encoded,
     username: token.unencoded.bot]
  end

  @spec frontend_topic(Token.t) :: String.t
  defp frontend_topic(%Token{} = token), do: "bot/#{token.unencoded.bot}/from_device"

  @spec bot_topic(Token.t) :: String.t
  defp bot_topic(%Token{} = token), do: "bot/#{token.unencoded.bot}/from_clients"

  # NOT WORKING
  # @spec build_last_will_message :: String.t
  # defp build_last_will_message do
  #   msg = Farmbot.RPC.Handler.log_msg("Bot going offline",
  #                                      [:error_ticker],
  #                                      ["ERROR"])
  #   IO.inspect msg
  #   msg
  # end
end
