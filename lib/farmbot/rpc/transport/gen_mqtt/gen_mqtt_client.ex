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
    Logger.debug ">> is up and running!"
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
     username: token.unencoded.bot,
     last_will_topic: [frontend_topic(token)],
     last_will_msg: build_last_will_message(token),
     last_will_qos: 1
    ]
  end

  @spec frontend_topic(Token.t) :: String.t
  defp frontend_topic(%Token{} = token), do: "bot/#{token.unencoded.bot}/from_device"

  @spec bot_topic(Token.t) :: String.t
  defp bot_topic(%Token{} = token), do: "bot/#{token.unencoded.bot}/from_clients"

  @spec build_last_will_message(Token.t) :: binary
  defp build_last_will_message(%Token{} = token) do
    msg =
      %{message: token.unencoded.bot <> " is offline!",
        created_at: :os.system_time(:seconds),
        channels: [:toast],
        meta: %{
          type: :error,
          x: -1,
          y: -1,
          z: -1 }}

      %RPC.Spec.Notification{
        id: nil,
        method: "log_message",
        params: [msg]}
      |> Poison.encode!
  end
end
