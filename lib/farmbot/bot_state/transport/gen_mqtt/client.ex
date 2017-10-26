defmodule Farmbot.BotState.Transport.GenMQTT.Client do
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
    {:ok, %{connected: false, device: device, cache: nil}}
  end

  def on_connect_error(:invalid_credentials, state) do
    msg = """
    Failed to authenticate with the message broker.
    This is likely a problem with your server/broker configuration.
    """

    Logger.error(msg)
    Farmbot.System.factory_reset(msg)
    {:ok, state}
  end

  def on_connect_error(reason, state) do
    Logger.error(">> Failed to connect to mqtt: #{inspect(reason)}")
    {:ok, state}
  end

  def on_connect(state) do
    GenMQTT.subscribe(self(), [{bot_topic(state.device), 0}])
    GenMQTT.subscribe(self(), [{sync_topic(state.device), 0}])
    Logger.info("Connected!")

    if state.cache do
      GenMQTT.publish(self(), status_topic(state.device), state.cache, 0, false)
    end

    {:ok, %{state | connected: true}}
  end

  def on_publish(["bot", _bot, "from_clients"], msg, state) do
    Logger.warn("not implemented yet: #{inspect Poison.decode!(msg)}")
    msg
    |> Poison.decode!()
    |> Farmbot.CeleryScript.AST.parse()
    |> Farmbot.CeleryScript.VirtualMachine.execute()
    {:ok, state}
  end

  def on_publish(["bot", _bot, "sync"], msg, state) do
    sync_cmd = msg |> Poison.decode!()
    repo = Farmbot.Repo.other_repo()
    mod = Module.concat(["Farmbot", "Repo", sync_cmd["kind"]])
    if Code.ensure_loaded?(mod) do
      Logger.warn "Updating #{sync_cmd["kind"]} => #{sync_cmd["body"]["id"]}"
      obj = sync_cmd["body"] |> Poison.encode! |> Poison.decode!(as: struct(mod))

      # require IEx; IEx.pry
      # We need to check if this object exists in the database.
      case repo.get(mod, obj.id) do
        # If it does not, just return the newly created object.
        nil -> obj

        # if there is an existing record, copy the ecto  meta from the old
        # record. This allows `insert_or_update` to work properly.
        existing -> %{obj | __meta__: existing.__meta__}
      end
      |> mod.changeset()
      |> repo.insert_or_update!()
    else
      Logger.warn "Unknown module: #{mod} #{inspect sync_cmd["body"]}"
    end
    {:ok, state}
  end

  def handle_cast({:bot_state, bs}, state) do
    json = Poison.encode!(bs)
    GenMQTT.publish(self(), status_topic(state.device), json, 0, false)
    {:noreply, %{state | cache: json}}
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
  defp sync_topic(bot), do: "bot/#{bot}/sync"
  defp status_topic(bot), do: "bot/#{bot}/status"
  defp log_topic(bot), do: "bot/#{bot}/logs"
end
