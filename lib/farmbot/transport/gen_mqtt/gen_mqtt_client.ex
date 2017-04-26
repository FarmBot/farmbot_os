defmodule Farmbot.Transport.GenMqtt.Client do
  @moduledoc """
    MQTT transport for farmbot RPC Commands.
  """
  use GenMQTT
  require Logger
  alias Farmbot.Transport.Serialized, as: Ser
  alias Farmbot.Token
  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast

  @type ok :: {:ok, Token.t}

  @spec init(Token.t) :: ok
  def init(%Token{} = token) do
    Logger.debug ">> Starting mqtt!"
    {:ok, token}
  end

  @doc """
    Starts a mqtt client.
  """
  @spec start_link(Token.t) :: {:ok, pid}
  def start_link(%Token{} = token) do
    GenMQTT.start_link(__MODULE__, token, build_opts(token))
  end

  @spec on_connect(Token.t) :: ok
  def on_connect(%Token{} = token) do
    GenMQTT.subscribe(self(), [{bot_topic(token), 0}])
    Logger.info ">> is up and running!"
    {:ok, token}
  end

  @spec on_publish([String.t], binary, Token.t) :: ok
  def on_publish(["bot", _bot, "from_clients"], msg, %Token{} = token) do
    msg
    |> Poison.decode!
    |> Ast.parse
    |> Command.do_command
    {:ok, token}
  end

  def on_disconnect(_), do: :shutdown

  def handle_cast({:status, %Ser{} = ser}, %Token{} = token) do
    json = Poison.encode!(ser)
    GenMQTT.publish(self(), status_topic(token), json, 0, false)
    {:ok, token}
  end

  def handle_cast({:log, msg}, %Token{} = token) do
    json = Poison.encode! msg
    GenMQTT.publish(self(), log_topic(token), json, 0, false)
    {:ok, token}
  end

  def handle_cast({:emit, msg}, %Token{} = token) do
    json = Poison.encode! msg
    GenMQTT.publish(self(), frontend_topic(token), json, 0, false)
    {:noreply, token}
  end

  def terminate(_,_), do: :ok

  @spec build_opts(Token.t) :: GenMQTT.option
  defp build_opts(%Token{} = token) do
    [name: __MODULE__,
     host: token.unencoded.mqtt,
     timeout: 10_000,
     reconnect_timeout: 10_000,
     password: token.encoded,
     username: token.unencoded.bot,
     last_will_topic: [log_topic(token)],
     last_will_msg: build_last_will_message(token),
     last_will_qos: 0
    ]
  end

  @spec frontend_topic(Token.t) :: String.t
  defp frontend_topic(%Token{} = token),
    do: "bot/#{token.unencoded.bot}/from_device"

  @spec bot_topic(Token.t) :: String.t
  defp bot_topic(%Token{} = token),
    do: "bot/#{token.unencoded.bot}/from_clients"

  @spec status_topic(Token.t) :: String.t
  defp status_topic(%Token{} = token),
    do: "bot/#{token.unencoded.bot}/status"

  @spec log_topic(Token.t) :: String.t
  defp log_topic(%Token{} = token),
    do: "bot/#{token.unencoded.bot}/logs"

  @spec build_last_will_message(Token.t) :: binary
  defp build_last_will_message(%Token{} = token) do
    %{message: token.unencoded.bot <> " is offline!",
      created_at: :os.system_time(:seconds),
      channels: [:toast],
      meta: %{
        type: :error,
        x: -1,
        y: -1,
        z: -1}}
    |> Poison.encode!
  end

  @doc """
    Cast info to a client
  """
  @spec cast(pid, any) :: no_return
  def cast(pid, info), do: GenMQTT.cast(pid, info)
end
