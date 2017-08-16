defmodule Farmbot.BotState.Transport.GenMqtt do
  @moduledoc "Default MQTT Transport."

  @behaviour Farmbot.BotState.Transport
  use GenMQTT
  require Logger

  defmodule State do
    @moduledoc false
    defstruct [bot: nil, connected: false]
  end

  def emit(msg) do
    GenMQTT.cast(__MODULE__, {:emit, msg})
  end

  def log(log) do
    GenMQTT.cast(__MODULE__, {:log, log})
  end

  def start_link(bin_token, bot_state_tracker, opts \\ []) do
    token = Farmbot.Jwt.decode!(bin_token)
    GenMQTT.start_link(__MODULE__, [token.bot, bot_state_tracker], build_opts(bin_token, token, opts))
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
    json = Poison.encode!(bs)
    GenMQTT.publish(self(), status_topic(state.bot), json, 0, false)
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

  defp build_last_will_message(bot) do
    %{message: bot <> " is offline!",
      created_at: :os.system_time(:seconds),
      channels: [:toast],
      meta: %{
        type: :error,
        x: -1,
        y: -1,
        z: -1}}
    |> Poison.encode!
  end

  defp build_opts(bin_token, %{mqtt: mqtt, bot: bot}, opts) do
    [
      reconnect_timeout: 10_000,
      last_will_topic:   [log_topic(bot)],
      last_will_msg:     build_last_will_message(bot),
      last_will_qos:     0,
      username:          bot,
      password:          bin_token,
      timeout:           10_000,
      host:              mqtt
    ]
    |> Keyword.merge(opts)
  end

end
