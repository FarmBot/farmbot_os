defmodule Farmbot.BotState.Transport.AMQP do
  @moduledoc "AMQP Bot State Transport."

  use GenStage
  use AMQP
  use Farmbot.Logger

  alias Farmbot.CeleryScript
  alias CeleryScript.AST

  import Farmbot.BotState.Utils

  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [get_config_value: 3, update_config_value: 4]

  @exchange "amq.topic"

  @doc false
  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def stop(reason \\ :normal) do
    if Process.whereis(__MODULE__) do
      GenStage.stop(__MODULE__, reason)
    else
      :ok
    end
  end

  # GenStage callbacks

  defmodule State do
    @moduledoc false
    defstruct [:conn, :chan, :bot, :state_cache]
  end

  def init([]) do
    token = ConfigStorage.get_config_value(:string, "authorization", "token")
    email = ConfigStorage.get_config_value(:string, "authorization", "email")

    import Farmbot.Jwt, only: [decode: 1]
    with {:ok, %{bot: device, mqtt: mqtt_host, vhost: vhost}} <- decode(token),
         {:ok, conn}  <- open_connection(token, email, device, mqtt_host, vhost),
         {:ok, chan}  <- AMQP.Channel.open(conn),
         q_base       <- device,

         :ok          <- Basic.qos(chan, [global: true]),
         {:ok, _}     <- AMQP.Queue.declare(chan, q_base <> "_from_clients", [auto_delete: true]),
         from_clients <- [routing_key: "bot.#{device}.from_clients"],
         {:ok, _}     <- AMQP.Queue.purge(chan, q_base <> "_from_clients"),
         :ok          <- AMQP.Queue.bind(chan, q_base <> "_from_clients", @exchange, from_clients),

         {:ok, _}     <- AMQP.Queue.declare(chan, q_base <> "_auto_sync", [auto_delete: false]),
         sync         <- [routing_key: "bot.#{device}.sync.#"],
         :ok          <- AMQP.Queue.bind(chan, q_base <> "_auto_sync", @exchange, sync),

         {:ok, _tag}  <- Basic.consume(chan, q_base <> "_from_clients", self(), [no_ack: true]),
         {:ok, _tag}  <- Basic.consume(chan, q_base <> "_auto_sync", self(), [no_ack: true]),
         state <- %State{conn: conn, chan: chan, bot: device}
    do
      _ = Process.monitor(conn.pid)
      _ = Process.monitor(chan.pid)
      _ = Process.flag(:sensitive, true)
      _ = Process.flag(:trap_exit, true)
      {:consumer, state, subscribe_to: [Farmbot.BotState, Farmbot.Logger]}
    else
      {:error, {:auth_failure, msg}} = fail ->
        Farmbot.System.factory_reset(msg)
        {:stop, fail}
      {:error, err} ->
        msg = "Got error authenticating with Real time services: #{inspect err}"
        Logger.error 1, msg

        # If the auth task is running, force it to reset.
        if Process.whereis(Farmbot.Bootstrap.AuthTask) do
          Farmbot.Bootstrap.AuthTask.force_refresh()
        end
        :ignore
    end
  end

  defp open_connection(token, email, bot, mqtt_server, vhost) do
    opts = [
    client_properties: [
      {"version", :longstr, Farmbot.Project.version()},
      {"commit", :longstr, Farmbot.Project.commit()},
      {"target", :longstr, Farmbot.Project.target()},
      {"opened", :longstr, to_string(DateTime.utc_now())},
      {"product", :longstr, "farmbot_os"},
      {"bot", :longstr, bot},
      {"email", :longstr, email},
      {"node", :longstr, to_string(node())},
    ],
    host: mqtt_server,
    username: bot,
    password: token,
    virtual_host: vhost]

    case AMQP.Connection.open(opts) do
      {:ok, conn} -> {:ok, conn}
      {:error, reason} ->
        Logger.error 1, "Error connecting to AMPQ: #{inspect reason}"
        Process.sleep(5000)
        open_connection(token, email, bot, mqtt_server, vhost)
    end
  end

  def terminate(reason, state) do
    ok_reasons = [:normal, :shutdown, :token_refresh]
    update_config_value(:bool, "settings", "ignore_fbos_config", false)
    update_config_value(:bool, "settings", "ignore_fw_config", false)

    if reason not in ok_reasons do
      Logger.error 1, "AMQP Died: #{inspect reason}"
      update_config_value(:bool, "settings", "log_amqp_connected", true)
    end

    # If a channel was still open, close it.
    if state.chan, do: AMQP.Channel.close(state.chan)

    # If the connection is still open, close it.
    if state.conn, do: AMQP.Connection.close(state.conn)

    # If the auth task is running, force it to reset.
    auth_task = Farmbot.Bootstrap.AuthTask
    if Process.whereis(auth_task) && reason not in ok_reasons do
      auth_task.force_refresh()
      Farmbot.BotState.set_connected(false)
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
      if should_log?(log.module, log.verbosity) do
        fb = %{position: %{x: -1, y: -1, z: -1}}
        location_data = Map.get(state.state_cache || %{}, :location_data, fb)
        log_without_pos = %{
          type: log.level,
          x: nil, y: nil, z: nil,
          verbosity: log.verbosity,
          major_version: log.version.major,
          minor_version: log.version.minor,
          patch_version: log.version.patch,
          created_at: log.time,
          channels: log.meta[:channels] || [],
          message: log.message
        }
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
        unless new_bot_state == state.state_cache do
          push_bot_state(state.chan, state.bot, new_bot_state)
        end
        handle_bot_state_events(rest, %{state | state_cache: new_bot_state})
    end
  end

  def handle_bot_state_events([], state) do
    {:noreply, [], state}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, _}, state) do
    if get_config_value(:bool, "settings", "log_amqp_connected") do
      Logger.success(1, "Farmbot is up and running!")
      update_config_value(:bool, "settings", "log_amqp_connected", false)
    end
    Farmbot.BotState.set_connected(true)
    {:noreply, [], state}
  end

  # Sent by the broker when the consumer is
  # unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, _}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, _}, state) do
    {:noreply, [], state}
  end

  def handle_info({:basic_deliver, payload, %{routing_key: key}}, state) do
    if GenServer.whereis(Farmbot.Repo) do
      device = state.bot
      route = String.split(key, ".")
      case route do
        ["bot", ^device, "from_clients"] ->
          handle_celery_script(payload, state)
          {:noreply, [], state}
        ["bot", ^device, "sync", resource, _]
        when resource in ["Log", "User", "Image", "WebcamFeed"] ->
          {:noreply, [], state}
        ["bot", ^device, "sync", "FbosConfig", id] ->
          handle_fbos_config(id, payload, state)
        ["bot", ^device, "sync", "FirmwareConfig", id] ->
          handle_fw_config(id, payload, state)
        ["bot", ^device, "sync", resource, id] ->
          handle_sync_cmd(resource, id, payload, state)
        ["bot", ^device, "logs"]        -> {:noreply, [], state}
        ["bot", ^device, "status"]      -> {:noreply, [], state}
        ["bot", ^device, "from_device"] -> {:noreply, [], state}
        _ ->
          Logger.warn 3, "got unknown routing key: #{key}"
          {:noreply, [], state}
      end
    else
      Logger.debug 3, "Repo not up yet."
      {:noreply, [], state}
    end
  end

  def handle_info({:DOWN, _, :process, pid, reason}, %{conn: %{pid: pid}} = state) do
    {:stop, reason, state}
  end

  def handle_info({:DOWN, _, :process, pid, reason}, %{chan: %{pid: pid}} = state) do
    {:stop, reason, state}
  end

  def handle_info({:DOWN, _, :process, pid, reason}, state) do
    unless reason in [:normal, :noproc] do
      Logger.warn 3, "CeleryScript: #{inspect pid} died: #{inspect reason}"
    end
    {:noreply, [], state}
  end

  @doc false
  def handle_celery_script(payload, _state) do
    case AST.decode(payload) do
      {:ok, ast} ->
        pid = spawn(CeleryScript, :execute, [ast])
        # Logger.busy 3, "CeleryScript starting: #{inspect pid}"
        Process.monitor(pid)
        :ok
      _ -> :ok
    end
  end

  @doc false
  def handle_sync_cmd(kind, id, payload, state) do
    mod = Module.concat(["Farmbot", "Asset", kind])
    if Code.ensure_loaded?(mod) do
      %{
        "body" => body,
        "args" => %{"label" => uuid}
      } = Poison.decode!(payload, as: %{"body" => struct(mod)})

      _cmd = ConfigStorage.register_sync_cmd(String.to_integer(id), kind, body)
      # This if statment should really not live here..
      if get_config_value(:bool, "settings", "auto_sync") do
        Farmbot.Repo.fragment_sync()
      else
        Farmbot.BotState.set_sync_status(:sync_now)
      end
      {:ok, %Macro.Env{}} = AST.Node.RpcOk.execute(%{label: uuid}, [], struct(Macro.Env))
    else
      %{
        "body" => _body,
        "args" => %{"label" => uuid}
      } = Poison.decode!(payload)
      msg = "Unknown syncable: #{mod}"
      {:ok, expl, %Macro.Env{}} = AST.Node.Explanation.execute(%{message: msg}, [], struct(Macro.Env))
      {:ok, %Macro.Env{}} = AST.Node.RpcError.execute(%{label: uuid}, [expl], struct(Macro.Env))
    end
    {:noreply, [], state}
  end

  def handle_fbos_config(_, _, %{state_cache: nil} = state) do
    # Don't update fbos config, if we don't have a state cache for whatever reason.
    {:noreply, [], state}
  end

  def handle_fbos_config(_id, payload, state) do
    if get_config_value(:bool, "settings", "ignore_fbos_config") do
      IO.puts "Ignoring OS config from AMQP."
      {:noreply, [], state}
    else
      case Poison.decode(payload) do
        {:ok, %{"body" => %{"api_migrated" => true} = config}} ->
          # Logger.info 1, "Got fbos config from amqp: #{inspect config}"
          old = state.state_cache.configuration
          updated = Farmbot.Bootstrap.SettingsSync.apply_fbos_map(old, config)
          push_bot_state(state.chan, state.bot, %{state.state_cache | configuration: updated})
          {:noreply, [], state}
        _ -> {:noreply, [], state}
      end
    end
  end

  def handle_fw_config(_id, payload, state) do
    if get_config_value(:bool, "settings", "ignore_fw_config") do
      IO.puts "Ignoring FW config from AMQP."
      {:noreply, [], state}
    else
      case Poison.decode(payload) do
        {:ok, %{"body" => %{} = config}} ->
          old = state.state_cache.mcu_params
          _new = Farmbot.Bootstrap.SettingsSync.apply_fw_map(old, config)
          {:noreply, [], state}
        _ -> {:noreply, [], state}
        end
    end
  end

  defp push_bot_log(chan, bot, log) do
    json = Poison.encode!(log)
    :ok = AMQP.Basic.publish chan, @exchange, "bot.#{bot}.logs", json
  end

  defp emit_cs(chan, bot, cs) do
    with {:ok, map} <- AST.encode(cs),
         {:ok, json} <- Poison.encode(map)
    do
      :ok = AMQP.Basic.publish chan, @exchange, "bot.#{bot}.from_device", json
    end
  end

  defp push_bot_state(chan, bot, state) do
    json = Poison.encode!(state)
    :ok = AMQP.Basic.publish chan, @exchange, "bot.#{bot}.status", json
  end

  defp add_position_to_log(%{} = log, %{position: pos}) do
    Map.merge(log, pos)
  end
end
