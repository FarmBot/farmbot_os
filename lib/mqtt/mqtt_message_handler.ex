alias Experimental.{GenStage}
defmodule MqttMessageHandler do
  use GenStage
  require Logger

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(_args) do
    {:ok, client} = Mqtt.Client.start_link(%{parent: __MODULE__})
    Logger.debug("Started Mqtt Client")
    spawn fn -> log_in end
    {:consumer, client, subscribe_to: [MqttMessageManager]}
  end

  def handle_events(events, _from, client) do
    do_events(events, client)
  end

  def do_events([], client) do
    {:noreply, [], client}
  end

  def do_events(events, client) do
    event = List.first(events)
    case handle_event(event,client) do
      :ok -> do_events(events -- [event], client) # event was done successfully.
      :no_handler -> do_events(events -- [event], client) # Event wasnt done because there was no handler for it.
      {:error, :econnrefused} -> # happens on bad log in. Needs work
        GenStage.call(MqttMessageManager, {:notify, event}) # put the event back at the end
        do_events(events -- [event], client)
      error ->
        Logger.error("Event: #{inspect event} failed because #{inspect error}")
        do_events(events, client)
        {:noreply, [], client }
    end
  end

  def handle_event({:login, options}, client) do
    Mqtt.Client.connect(client, options)
  end

  def handle_event({:emit, message}, client) when is_bitstring(message) do
    options = [ id: 1234,
                topic: "bot/#{bot}/from_device",
                message: message,
                dup: 1, qos: 1, retain: 0]
    Mqtt.Client.publish(client, options)
  end

  def handle_event({:on_connect_ack, _message}, client) do
    options = [id: 24756, topics: ["bot/#{bot}/from_clients"], qoses: [0]]
    keep_connection_alive
    Logger.debug("Connect Ack")
    NetworkSupervisor.set_time # Should NOT be here
    Mqtt.Client.subscribe(client, options)
    Command.read_all_pins # I'm truly sorry these are here
    Command.read_all_params
    BotSync.sync
    :ok
  end

  def handle_event({:on_subscribed_publish, message}, _client) do
    Map.get(message, :message) |> Poison.decode! |>
    RPCMessageManager.sync_notify
  end

  def handle_event({:on_connect, _message}, _client) do
    :ok
  end

  def handle_event({:on_subscribe, _message}, _client) do
    :ok
  end

  def handle_event({:on_subscribe_ack, _message}, _client) do
    :ok
  end

  def handle_event({:on_publish, _message}, _client) do
    :ok
  end

  def handle_event({:on_publish_ack, _message}, _client) do
    :ok
  end

  def handle_event(event, _client) do
    Logger.error("No handler for event: #{inspect event}")
    :no_handler
  end

  def handle_info(:keep_alive, client) do
    Mqtt.Client.ping(client)
    keep_connection_alive
  end

  def log_in do
    case Auth.get_token do
      {:error, reason} ->
        Logger.error("Mqtt login failed: #{inspect reason}")
        log_in
      nil -> log_in
      token ->
        mqtt_host = Map.get(token, "unencoded") |> Map.get("mqtt")
        mqtt_user = Map.get(token, "unencoded") |> Map.get("bot")
        mqtt_pass = Map.get(token, "encoded")
        options = [client_id: mqtt_user,
                   username: mqtt_user,
                   password: mqtt_pass,
                   host: mqtt_host,
                   port: 1883,
                   timeout: 5000,
                   keep_alive: 500,
                   will_topic: "bot/#{bot}/from_device",
                   will_message: build_last_will_message,
                   will_qos: 0,
                   will_retain: 0]
        GenStage.call(MqttMessageManager, {:notify, {:login, options}})
    end
  end

  defp build_last_will_message do
    RPCMessageHandler.log_msg("Something TERRIBLE Happened. Bot going offline.", ["error_ticker"])
  end

  defp bot do
    Map.get(Auth.get_token, "unencoded") |>  Map.get("bot")
  end

  defp keep_connection_alive do
    Process.send_after(__MODULE__, :keep_alive, 15000)
  end

  def emit(message) when is_bitstring message do
    GenStage.call(MqttMessageManager, {:notify, {:emit, message}})
  end
end
