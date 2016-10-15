defmodule MqttHandler do
  require GenServer
  require Logger

  defp build_last_will_message do
    RPCMessageHandler.log_msg("Something TERRIBLE Happened. Bot going offline.", ["ticker_error"])
  end

  @doc """
    "tries to log into mqtt."
  """
  def log_in(err_wait_time\\ 10000) do
    case token do
      {:error, reason} -> {:error, reason}
      real_token ->
        mqtt_host = Map.get(real_token, "unencoded") |> Map.get("mqtt")
        mqtt_user = Map.get(real_token, "unencoded") |> Map.get("bot")
        mqtt_pass = Map.get(real_token, "encoded")
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
        case GenServer.call(MqttHandler, {:log_in, options}) do
          {:error, reason} -> Logger.debug("Error connecting. #{inspect reason}")
                              Process.sleep(err_wait_time)
                              log_in(err_wait_time + 10000) # increment the sleep time for teh lawls
          :ok -> :ok
        end
    end
  end

  def init(_args) do
    Mqtt.Client.start_link(%{parent: __MODULE__})
  end

  def blah do
    case log_in do
      {:error, reason} -> Logger.debug("error connecting to mqtt")
                          IO.inspect(reason)
      :ok -> Logger.debug("MQTT ONLINE")
    end
  end

  def start_link(args) do
    handler = GenServer.start_link(__MODULE__, args, name: __MODULE__)
    spawn fn -> blah end
    handler
  end

  def handle_call({:connect, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:connect_ack, _message}, from, client) do
    options = [id: 24756, topics: ["bot/#{bot}/from_clients"], qoses: [0]]
    spawn fn ->
      Logger.debug("Connect Ack")
      NetworkSupervisor.set_time # Should NOT be here
      Mqtt.Client.subscribe(client, options)
      Logger.debug("Subscribing")
      handle_call({:emit, RPCMessageHandler.log_msg("Bot Bootstrapping")}, from, client)
      Logger.debug("Doing bot bootstrap")
      Command.read_all_pins # I'm truly sorry these are here
      Command.read_all_params
      handle_call({:emit, RPCMessageHandler.log_msg("Bot finished Bootstrapping")}, from, client)
    end
    keep_connection_alive
    {:reply, :ok, client}
  end

  def handle_call({:publish, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:subscribed_publish, message}, _from, client) do
    Map.get(message, :message) |> Poison.decode! |>
    RPCMessageManager.sync_notify
    {:reply, :ok, client}
  end

  def handle_call({:subscribed_publish_ack, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:publish_receive, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:publish_release, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:publish_complete, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:publish_ack, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:subscribe, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:subscribe_ack, _message}, from, client) do
    Logger.debug("Subscribed.")
    handle_call({:emit, RPCMessageHandler.log_msg("Bot Online", "ticker")}, from, client)
  end

  def handle_call({:unsubscribe, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:unsubscribe_ack, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:ping, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:disconnect, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:pong, _message}, _from, client) do
    {:reply, :ok, client}
  end

  def handle_call({:log_in, options}, _from, client) do
    case Mqtt.Client.connect(client, options) do
      {:error, reason} -> {:reply, {:error, reason}, client}
      :ok -> {:reply, :ok, client}
    end
  end

  def handle_call({:emit, message}, _from, client) when is_bitstring(message) do
    options = [ id: 1234,
                topic: "bot/#{bot}/from_device",
                message: message,
                dup: 1, qos: 1, retain: 0]
    spawn fn -> Mqtt.Client.publish(client, options) end
    {:reply, :ok, client}
  end

  def handle_call(thing, _from, client) do
    Logger.debug("Unhandled Thing #{inspect thing}")
    {:reply, :ok, client}
  end

  def handle_cast(event, state) do
    Logger.debug("#{inspect event}")
    {:noreply, state}
  end

  def handle_info({:keep_alive}, client) do
    Mqtt.Client.ping(client)
    keep_connection_alive
    {:noreply, client}
  end

  def emit(message) when is_bitstring(message) do
    GenServer.call(__MODULE__, {:emit, message})
  end

  defp bot do
    Map.get(token, "unencoded") |>  Map.get("bot")
  end

  defp token do
    Auth.fetch_token
  end

  defp keep_connection_alive do
    Process.send_after(__MODULE__, {:keep_alive}, 15000)
  end

  def terminate(reason, _state) do
    Logger.debug("MqttHandler died. #{inspect reason}")
  end
end
