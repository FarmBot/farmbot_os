defmodule Farmbot.Transport.GenMqtt.Client do
  @moduledoc """
    MQTT transport for farmbot RPC Commands.
  """
  require Logger
  alias   Farmbot.Transport.Serialized, as: Ser
  alias   Farmbot.Token
  alias   Farmbot.CeleryScript.{Command, Ast}
  alias   Farmbot.{Context, Token}
  use     Farmbot.DebugLog, name: MqttClient
  use     GenMQTT

  @doc """
    Starts a mqtt client.
  """
  def start_link(%Context{} = context, %Token{} = token) do
    GenMQTT.start_link(__MODULE__, {context, token}, build_opts(token))
  end

  def init({%Context{} = context, %Token{} = token}) do
    Logger.debug ">> Starting mqtt!"
    # Process.send_after(self(), :r_u_alive_bb?, 1000)
    {:ok, {token, context}}
  end

  def on_connect({%Token{} = token, %Context{} = context} = state) do
    GenMQTT.subscribe(self(), [{bot_topic(token), 0}])

    fn ->
      Process.sleep(10)
      Logger.info ">> is up and running!"
      Farmbot.Transport.force_state_push(context)
    end.()

    {:ok, state}
  end

  def on_publish(["bot", _bot, "from_clients"], msg, {%Token{} = token, %Context{} = context}) do
    try do
      new_context =
        msg
        |> Poison.decode!
        |> Ast.parse
        |> Command.do_command(context)
      {:ok, {token, new_context}}
    rescue
      e in Farmbot.CeleryScript.Error ->
        debug_log "CeleryScript execution error: #{inspect e}"
        Logger.info "CeleryScript execution error: #{e.message}", type: :error
        {:ok, {token, context}}
    end

  end

  def handle_cast({:status, %Ser{} = ser}, {%Token{} = token, %Context{} = con}) do
    # debug_log "Got bot status."
    json = Poison.encode!(ser)
    GenMQTT.publish(self(), status_topic(token), json, 0, false)
    {:ok, {token, con}}
  end

  def handle_cast({:log, msg}, {%Token{} = token, %Context{} = con}) do
    # debug_log "Got Log message."
    json = Poison.encode! msg
    GenMQTT.publish(self(), log_topic(token), json, 0, false)
    {:ok, {token, con}}
  end

  def handle_cast({:emit, msg}, {%Token{} = token, context}) do
    # debug_log "Emitting: #{inspect msg}"
    json = Poison.encode! msg
    GenMQTT.publish(self(), frontend_topic(token), json, 0, false)
    {:noreply, {token, context}}
  end

  # def handle_info(:r_u_alive_bb?, {%Token{} = tkn, %Context{} = ctx}) do
  #   # debug_log "Got alive checkup"
  #   Process.send_after(self(), :r_u_alive_bb?, 1000)
  #   {:noreply, {tkn, ctx}}
  # end

  @spec build_opts(Token.t) :: GenMQTT.option
  defp build_opts(%Token{} = token) do
    [
     reconnect_timeout: 10_000,
     last_will_topic:   [log_topic(token)],
     last_will_msg:     build_last_will_message(token),
     last_will_qos:     0,
     username:          token.unencoded.bot,
     password:          token.encoded,
     timeout:           10_000,
     host:              token.unencoded.mqtt,
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
