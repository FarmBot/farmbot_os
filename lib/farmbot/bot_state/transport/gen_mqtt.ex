defmodule Farmbot.BotState.Transport.GenMQTT do
  @moduledoc "MQTT BotState Transport."
  use GenStage
  require Logger

  defmodule Client do
    @moduledoc "Underlying client for interfacing MQTT."
    use GenMQTT
    require Logger

    @doc "Start a MQTT Client."
    def start_link(device, token, server) do
      GenMQTT.start_link(
        __MODULE__,
        {device, server},
        reconnect_timeout: 10000,
        username: device,
        password: token,
        timeout: 10000,
        host: server
      )
    end

    @doc "Push a bot state message."
    def push_bot_state(client, state) do
      GenMQTT.cast(client, {:bot_state, state})
    end

    @doc "Push a log message."
    def push_bot_log(client, log) do
      GenMQTT.cast(client, {:bot_log, log})
    end

    def init({device, _server}) do
      {:ok, %{connected: false, device: device}}
    end

    def on_connect_error(:invalid_credentials, state) do
      msg = """
      Failed to authenticate with the message broker!
      This is likely a problem with your server/broker configuration.
      """

      Logger.error(">> #{msg}")
      Farmbot.System.factory_reset(msg)
      {:ok, state}
    end

    def on_connect_error(reason, state) do
      Logger.error(">> Failed to connect to mqtt: #{inspect(reason)}")
      {:ok, state}
    end

    def on_connect(state) do
      GenMQTT.subscribe(self(), [{bot_topic(state.device), 0}])
      Logger.info(">> Connected!")
      {:ok, %{state | connected: true}}
    end

    def on_publish(["bot", _bot, "from_clients"], msg, state) do
      Logger.warn("not implemented yet: #{inspect(msg)}")
      {:ok, state}
    end

    def handle_cast({:bot_state, bs}, state) do
      json = Poison.encode!(bs)
      GenMQTT.publish(self(), status_topic(state.device), json, 0, false)
      {:noreply, state}
    end

    def handle_cast(_, %{connected: false} = state) do
      {:noreply, state}
    end

    def handle_cast({:bot_log, log}, state) do
      json = Poison.encode!(log)
      GenMQTT.publish(self(), log_topic(state.device), json, 0, false)
      {:noreply, state}
    end

    defp frontend_topic(bot), do: "bot/#{bot}/from_device"
    defp bot_topic(bot), do: "bot/#{bot}/from_clients"
    defp status_topic(bot), do: "bot/#{bot}/status"
    defp log_topic(bot), do: "bot/#{bot}/logs"
  end

  @doc "Start the MQTT Transport."
  def start_link(opts) do
    GenStage.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    token = Farmbot.System.ConfigStorage.get_config_value(:string, "authorization", "token")
    {:ok, %{bot: device, mqtt: mqtt_server}} = Farmbot.Jwt.decode(token)
    {:ok, client} = Client.start_link(device, token, mqtt_server)
    {:consumer, {%{client: client}, nil}, subscribe_to: [Farmbot.BotState, Farmbot.Logger]}
  end

  def handle_events(events, {pid, _}, state) do
    case Process.info(pid)[:registered_name] do
      Farmbot.Logger -> handle_log_events(events, state)
      Farmbot.BotState -> handle_bot_state_events(events, state)
    end
  end

  def handle_log_events(logs, {%{client: client} = internal_state, old_bot_state}) do
    for log <- logs do
      Client.push_bot_log(client, log)
    end

    {:noreply, [], {internal_state, old_bot_state}}
  end

  def handle_bot_state_events(events, {%{client: client} = internal_state, old_bot_state}) do
    new_bot_state = List.last(events)

    if new_bot_state != old_bot_state do
      Client.push_bot_state(client, new_bot_state)
    end

    {:noreply, [], {internal_state, new_bot_state}}
  end
end
