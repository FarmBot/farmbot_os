defmodule Farmbot.BotState.Transport.GenMqtt do
  @moduledoc "Default MQTT Transport."

  @behaviour Farmbot.BotState.Transport
  use GenMQTT
  require Logger

  # Callback function
  def emit(msg), do: emit(__MODULE__, msg)

  @doc "Emit a message on `client`."
  def emit(client, msg) do
    GenMQTT.cast(client, {:emit, msg})
  end

  # Callback function
  def log(log), do: log(__MODULE__, log)

  @doc "Log a message on `client`."
  def log(client, log) do
    GenMQTT.cast(client, {:log, log})
  end

  # Callback function.
  def start_link(bin_token, bot_state_tracker, name \\ __MODULE__) do
    token = Farmbot.Jwt.decode!(bin_token)
    GenMQTT.start_link(__MODULE__, [token.bot, bot_state_tracker], build_opts(bin_token, token, name))
  end

  ## Server Implementation.

  defmodule State do
    @moduledoc false
    defstruct [bot: nil, connected: false]
  end

  def init([bot, bot_state_tracker]) do
    :ok = Farmbot.BotState.subscribe(bot_state_tracker)
    {:ok, %State{bot: bot}}
  end

  def on_connect(state) do
    GenMQTT.subscribe(self(), [{bot_topic(state.bot), 0}])
    Logger.info ">> Connected!"
    {:ok, %{state | connected: true}}
  end

  def on_connect_error(:invalid_credentials, _) do
    msg = """
    Failed to authenticate with the message broker!
    This is likely a problem with your server/broker configuration.
    """
    Logger.error ">> #{msg}"
    Farmbot.System.factory_reset(msg)
    {:ok, state}
  end

  def on_connect_error(reason, state) do
    Logger.error ">> Failed to connect to mqtt: #{inspect reason}"
    {:ok, state}
  end

  def on_publish(["bot", _bot, "from_clients"], msg, state) do
    Logger.warn "not implemented yet: #{inspect msg}"
    {:ok, state}
  end

  def handle_info(_, %{connected: false} = state), do: {:ok, state}

  def handle_info({:bot_state, bs}, state) do
    Logger.info "Got bot state update"
    json = Poison.encode!(bs)
    GenMQTT.publish(self(), status_topic(state.bot), json, 0, false)
    {:noreply, state}
  end

  def handle_cast(_, %{connected: false} = state), do: {:noreply, state}

  def handle_cast({:log, msg}, state) do
    json = Poison.encode! msg
    GenMQTT.publish(self(), log_topic(state.bot), json, 0, false)
    {:noreply, state}
  end

  def handle_cast({:emit, msg}, state) do
    json = Poison.encode! msg
    GenMQTT.publish(self(), frontend_topic(state.bot), json, 0, false)
    {:noreply, state}
  end

  defp frontend_topic(bot), do: "bot/#{bot}/from_device"
  defp bot_topic(bot),      do: "bot/#{bot}/from_clients"
  defp status_topic(bot),   do: "bot/#{bot}/status"
  defp log_topic(bot),      do: "bot/#{bot}/logs"

  defp build_opts(bin_token, %{mqtt: mqtt, bot: bot}, name) do
    [
      name: name,
      reconnect_timeout: 10_000,
      username:          bot,
      password:          bin_token,
      timeout:           10_000,
      host:              mqtt
    ]
  end

end
