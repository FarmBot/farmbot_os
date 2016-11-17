defmodule Farmbot.RPC.Transport.Mqtt do
  require GenServer
  require Logger

  def init(_args) do
    Logger.debug("MQTT INIT")
    Process.flag(:trap_exit, true)
    {:ok, client} = Mqtt.Client.start_link(%{parent: self()})
    case Farmbot.Auth.get_token do
      {:ok, token} ->
        login(token)
        {:ok, {client, token}}
      _ ->
        {:ok, {client, nil}}
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # dont allow emits when we dont have a token
  def handle_cast(_, {client, nil}) do
    {:noreply, {client, nil}}
  end

  def handle_cast({:emit, message}, {client, token}) when is_bitstring(message) do
    options = [ id: 1234,
                topic: "bot/#{bot(token)}/from_device",
                message: message,
                dup: 1, qos: 1, retain: 0 ]
    spawn fn -> Mqtt.Client.publish(client, options) end
    {:noreply, {client, token}}
  end

  def handle_info(:login, {client, nil})
  when is_pid(client) do
    Logger.warn("This shouldn't be possible.")
  end

  def handle_info(:login, {client, token})
  when is_pid(client) do
    Logger.debug("Trying to sign into MQTT")
    resp = Mqtt.Client.connect(client, connect_options(token))
    Logger.debug("FINDME: #{inspect resp}")
    {:noreply, {client, token}}
  end

  def handle_info({:EXIT, pid, reason}, {client, token})
  when pid == client do
    Logger.error("Hulaki died: #{inspect reason}")
    {:crashme, {client, token}}
  end

  def handle_info({:EXIT, pid, reason}, {client, token}) do
    Logger.warn("something in mqtt.ex died: #{inspect pid}: #{inspect reason}")
    {:noreply, {client, token}}
  end

  def handle_info({:authorization, token}, {client, _old_token}) do
    login(token)
    {:noreply, {client, token}}
  end

  # We still want to keep alive, but dont actually preform the ping
  def handle_info({:keep_alive}, {client, nil}) do
    keep_connection_alive
    {:noreply, {client, nil}}
  end

  def handle_info({:keep_alive}, {client, token}) do
    Mqtt.Client.ping(client)
    keep_connection_alive
    {:noreply, {client, token}}
  end

  def emit(message) when is_bitstring(message) do
    GenServer.cast(__MODULE__, {:emit, message})
  end

  defp bot(token) do
    Map.get(token, "unencoded") |>  Map.get("bot")
  end

  defp keep_connection_alive do
    Process.send_after(__MODULE__, {:keep_alive}, 15000)
  end

  def terminate(reason, _state) do
    Logger.debug("#{__MODULE__} died. #{inspect reason}")
  end

  defp build_last_will_message do
    Farmbot.RPC.Handler.log_msg("Bot going offline", [:error_ticker], ["ERROR"])
  end

  defp login(token) when is_map(token) do
    # This wait fixes haluki crashing for some reason.
    Process.send_after(__MODULE__, :login, 2000)
  end

  defp connect_options(token) do
    mqtt_host = Map.get(token, "unencoded") |> Map.get("mqtt")
    mqtt_user = Map.get(token, "unencoded") |> Map.get("bot")
    mqtt_pass = Map.get(token, "encoded")
    [client_id: mqtt_user,
     username: mqtt_user,
     password: mqtt_pass,
     host: mqtt_host, # mqtt.farmbot.io
     port: 1883,
    #  port: 8883,
     timeout: 5000,
     keep_alive: 500,
     will_topic: "bot/#{bot(token)}/from_device",
     will_message: build_last_will_message,
     will_qos: 0,
     will_retain: 0]
  end

  ##                                ##
  #  Callbacks from the Mqtt_Client  #
  ##                                ##

  def handle_call(_, _, {client, nil}) do
    Logger.debug("MQTT Doesn't have a token yet.")
    {:reply, :no_token, {client, nil}}
  end

  def handle_call({:connect_ack, _message}, _from, {client, token}) do
    options = [id: 24756, topics: ["bot/#{bot(token)}/from_clients"], qoses: [0]]
    spawn fn ->
      Logger.debug("Subscribing")
      Mqtt.Client.subscribe(client, options)
      Farmbot.Sync.sync
    end
    keep_connection_alive
    {:reply, :ok, {client, token}}
  end

  def handle_call({:subscribed_publish, message}, _from, {client, token}) do
    Map.get(message, :message) |> Poison.decode! |>
    RPC.MessageManager.sync_notify
    {:reply, :ok, {client, token}}
  end

  def handle_call({:subscribe_ack, _message}, _from, {client, token}) do
    Logger.debug("Subscribed.")
    spawn fn ->
      Farmbot.Logger.log("Bot is online and ready to roll", [:ticker], ["BOT STATUS"])
    end
    {:reply, :ok, {client, token}}
  end

  ###                                                   ###
  #  THESE ARE ALL UNUSED CALLBACKS FROM THE MQTT_CLIENT  #
  ###                                                   ###
  def handle_call({:unsubscribe, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:unsubscribe_ack, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:ping, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:disconnect, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:pong, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:connect, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end
  def handle_call({:publish, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end
  def handle_call({:subscribed_publish_ack, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:publish_receive, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:publish_release, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:publish_complete, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:publish_ack, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call({:subscribe, _message}, _from, {client, token}) do
    {:reply, :ok, {client, token}}
  end

  def handle_call(thing, _from, {client, token}) do
    Logger.debug("Unhandled Thing #{inspect thing}")
    {:reply, :ok, {client, token}}
  end
end
