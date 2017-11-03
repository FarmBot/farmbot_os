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
    Logger.info ">> Starting mqtt!", type: :busy
    Process.flag(:trap_exit, true)
    {:ok, %{token: token, context: context, cs_nodes: []}}
  end

  def on_connect(%{token: token, context: context} = state) do
    GenMQTT.subscribe(self(), [{bot_topic(token), 0}])

    fn ->
      Process.sleep(10)
      Logger.flush()
      backend     = Logger.Backends.FarmbotLogger
      {:ok, _pid} = Logger.add_backend(backend)
      :ok         = GenEvent.call(Logger, backend, {:context, context})
      # Logger.info ">> is up and running!", type: :success
      debug_log "Connected to real time messaging."
      Farmbot.Transport.force_state_push(context)
    end.()

    {:ok, state}
  end

  def on_connect_error(:invalid_credentials, _) do
    msg = """
    Failed to authenticate with the message broker!
    This is likely a problem with your server/broker configuration.
    """
    Logger.error ">> #{msg}"
    Farmbot.System.factory_reset(msg)
  end

  def on_connect_error(reason, state) do
    Logger.error ">> Failed to connect to mqtt #{state.token.unencoded.mqtt}: #{inspect reason}"
    {:ok, state}
  end

  def on_publish(["bot", _bot, "from_clients"], msg, state) do
    this = self()
    pid = spawn fn() ->
      new_context =
        msg
        |> Poison.decode!
        |> Ast.parse
        |> Command.do_command(state.context)
        cast(this, {:context, self(), new_context})
    end
    {:ok, %{state | cs_nodes: [pid | state.cs_nodes]}}
  end

  def handle_cast(_, %{token: nil} = state), do: {:stop, :no_token, state}

  def handle_cast({:context, pid, %Context{} = ctx}, state)do
    new_nodes = List.delete(state.cs_nodes, pid)
    {:ok, %{state | context: ctx, cs_nodes: new_nodes}}
  end

  def handle_cast({:status, %Ser{} = ser}, state) do
    # debug_log "Got bot status."
    json = Poison.encode!(ser)
    GenMQTT.publish(self(), status_topic(state.token), json, 0, false)
    {:ok, state}
  end

  def handle_cast({:log, msg}, state) do
    # debug_log "Got Log message."
    json = Poison.encode! msg
    # c = self()
    # require IEx; IEx.pry
    GenMQTT.publish(self(), log_topic(state.token), json, 0, false)
    {:ok, state}
  end

  def handle_cast({:emit, msg}, state) do
    # debug_log "Emitting: #{inspect msg}"
    json = Poison.encode! msg
    GenMQTT.publish(self(), frontend_topic(state.token), json, 0, false)
    {:noreply, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    if pid in state.cs_nodes do
      # this step did not execute properly.
      {:ok, %{state | cs_nodes: List.delete(state.cs_nodes, pid)}}
    else
      {:ok, state}
    end
  end

  def terminate(_, _) do
    be = Logger.Backends.FarmbotLogger
    Logger.remove_backend(be)
  end

  @spec build_opts(Token.t) :: GenMQTT.option
  defp build_opts(%Token{} = token) do
    [
     clean_session: true,
     reconnect_timeout: 10_000,
     timeout:           10_000,
     last_will_topic:   [log_topic(token)],
     last_will_msg:     build_last_will_message(token),
     last_will_qos:     0,
     last_will_retain:  false,
     username:          token.unencoded.bot,
     client:            token.unencoded.bot <> "-" <> UUID.uuid1,
     password:          token.encoded,
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
