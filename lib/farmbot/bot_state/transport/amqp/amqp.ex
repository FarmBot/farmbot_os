defmodule Farmbot.BotState.Transport.AMQP do
  @moduledoc "AMQP Bot State Transport."

  use GenStage
  use AMQP
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage
  alias Farmbot.CeleryScript
  alias CeleryScript.AST

  @exchange "amq.topic"

  @doc false
  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  # GenStage callbacks

  defmodule State do
    @moduledoc false
    defstruct [:conn, :chan, :queue_name, :bot, :state_cache]
  end

  def init([]) do
    token = ConfigStorage.get_config_value(:string, "authorization", "token")
    with {:ok, %{bot: device, mqtt: mqtt_server, virtual_host: vhost}} <- Farmbot.Jwt.decode(token),
         {:ok, conn} <- AMQP.Connection.open([host: mqtt_server, username: device, password: token, virtual_host: vhost || "/"]),
         {:ok, chan} <- AMQP.Channel.open(conn),
         queue_name  <- Enum.join([device, UUID.uuid1()], "-"),
         :ok         <- Basic.qos(chan, []),
         {:ok, _}    <- AMQP.Queue.declare(chan, queue_name, [auto_delete: true]),
         :ok         <- AMQP.Queue.bind(chan, queue_name, @exchange, [routing_key: "bot.#{device}.from_clients"]),
         :ok         <- AMQP.Queue.bind(chan, queue_name, @exchange, [routing_key: "bot.#{device}.sync.#"]),
         {:ok, _tag} <- Basic.consume(chan, queue_name),
         state       <- struct(State, [conn: conn, chan: chan, queue_name: queue_name, bot: device])
    do
      Logger.success(3, "Connected to real time services.")
      {:consumer, state, subscribe_to: [Farmbot.BotState, Farmbot.Logger]}
    else
      {:error, {:auth_failure, msg}} = fail ->
        Farmbot.System.factory_reset(msg)
        {:stop, fail, :no_state}
      {:error, reason} ->
        Logger.error 1, "Got error authenticating with Real time services: #{inspect reason}"
        :ignore
    end
  end

  def handle_events(events, {pid, _}, state) do
    case Process.info(pid)[:registered_name] do
      Farmbot.Logger -> handle_log_events(events, state)
      Farmbot.BotState -> handle_bot_state_events(events, state)
    end
  end

  def handle_log_events(logs, state) do
    for %Farmbot.Log{} = log <- logs do
      if log.module == nil or (Module.split(log.module || Elixir.Logger) |> List.first == "Farmbot") do
        location_data = Map.get(state.state_cache || %{}, :location_data, %{position: %{x: -1, y: -1, z: -1}})
        meta = %{type: log.level, x: nil, y: nil, z: nil}
        log_without_pos = %{created_at: log.time, meta: meta, channels: log.meta[:channels] || [], message: log.message}
        log = add_position_to_log(log_without_pos, location_data)
        push_bot_log(state.chan, state.bot, log)
      end
    end

    {:noreply, [], state}
  end

  def handle_bot_state_events([event | rest], state) do
    case event do
      {:emit, %AST{} = ast} ->
        emit_cs(state.chan, state.bot, ast)
        handle_bot_state_events(rest, state)
      new_bot_state ->
        push_bot_state(state.chan, state.bot, new_bot_state)
        handle_bot_state_events(rest, %{state | state_cache: new_bot_state})
    end
  end

  def handle_bot_state_events([], state) do
    {:noreply, [], state}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, _}, state) do
    {:noreply, [], state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, _}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, _}, state) do
    {:noreply, [], state}
  end

  def handle_info({:basic_deliver, payload, %{routing_key: key}}, state) do
    device = state.bot
    route = String.split(key, ".")
    case route do
      ["bot", ^device, "from_clients"] ->
        handle_celery_script(payload, state)
        {:noreply, [], state}
      ["bot", ^device, "sync", resource, _]
      when resource in ["Log", "User", "Image", "WebcamFeed"] ->
        {:noreply, [], state}
      ["bot", ^device, "sync", resource, id] ->
        handle_sync_cmd(resource, id, payload, state)
      ["bot", ^device, "logs"  ]      -> {:noreply, [], state}
      ["bot", ^device, "status"]      -> {:noreply, [], state}
      ["bot", ^device, "from_device"] -> {:noreply, [], state}
      _ ->
        Logger.warn 3, "got unknown routing key: #{key}"
        {:noreply, [], state}
    end
  end

  defp handle_celery_script(payload, _state) do
    case AST.decode(payload) do
      {:ok, ast} -> spawn CeleryScript, :execute, [ast]
      _ -> :ok
    end
  end

  defp handle_sync_cmd(kind, id, payload, state) do
    mod = Module.concat(["Farmbot", "Repo", kind])
    if Code.ensure_loaded?(mod) do
      %{"body" => body, "args" => %{"label" => uuid}} = Poison.decode!(payload, as: %{"body" => struct(mod)})
      Farmbot.Repo.register_sync_cmd(String.to_integer(id), kind, body)

      if Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "auto_sync") do
        Farmbot.Repo.flip()
      end

      Farmbot.CeleryScript.AST.Node.RpcOk.execute(%{label: uuid}, [], struct(Macro.Env))
    else
      Logger.warn 2, "Unknown syncable: #{mod}: #{inspect Poison.decode!(payload)}"
    end
    {:noreply, [], state}
  end

  defp push_bot_log(chan, bot, log) do
    json = Poison.encode!(log)
    :ok = AMQP.Basic.publish chan, @exchange, "bot.#{bot}.logs", json
  end

  defp emit_cs(chan, bot, cs) do
    with {:ok, map} <- Farmbot.CeleryScript.AST.encode(cs),
         {:ok, json} <- Poison.encode(map)
    do
      :ok = AMQP.Basic.publish chan, @exchange, "bot.#{bot}.from_device", json
    end
  end

  defp push_bot_state(chan, bot, state) do
    json = Poison.encode!(state)
    :ok = AMQP.Basic.publish chan, @exchange, "bot.#{bot}.status", json
  end

  defp add_position_to_log(%{meta: meta} = log, %{position: pos}) do
    new_meta = Map.merge(meta, pos)
    %{log | meta: new_meta}
  end
end
