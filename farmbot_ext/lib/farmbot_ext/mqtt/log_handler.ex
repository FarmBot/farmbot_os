defmodule FarmbotExt.MQTT.LogHandler do
  @moduledoc """
  Publishes JSON encoded bot state updates onto an MQTT channel
  """

  use GenServer

  require FarmbotCore.Logger
  require FarmbotTelemetry
  require Logger

  alias FarmbotCore.{BotState, JSON}
  alias FarmbotExt.MQTT
  alias __MODULE__, as: State

  defstruct [:client_id, :username, :state_cache]

  @checkup_ms 50

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    state = %State{
      client_id: Keyword.fetch!(args, :client_id),
      username: Keyword.fetch!(args, :username)
    }

    {:ok, state, 0}
  end

  def handle_info(:timeout, %{state_cache: nil} = state) do
    initial_bot_state = BotState.subscribe()
    FarmbotExt.Time.no_reply(%{state | state_cache: initial_bot_state}, 0)
  end

  def handle_info(:timeout, state) do
    {:noreply, state, {:continue, FarmbotCore.Logger.handle_all_logs()}}
  end

  def handle_info({BotState, change}, state) do
    new_state_cache = Ecto.Changeset.apply_changes(change)
    {:noreply, %{state | state_cache: new_state_cache}, @checkup_ms}
  end

  def handle_info(other, state) do
    IO.inspect("UNEXPECTED HANDLE_INFO: #{inspect(other)}")
    {:noreply, state, 0}
  end

  def handle_continue([log | rest], state) do
    case do_handle_log(log, state) do
      :ok ->
        {:noreply, state, {:continue, rest}}

      error ->
        Logger.error("Failed to upload log: #{inspect(error)}")
        # Reschedule log to be uploaded again
        FarmbotCore.Logger.insert_log!(log)
        {:noreply, state, @checkup_ms}
    end
  end

  def handle_continue([], state) do
    {:noreply, state, @checkup_ms}
  end

  defp do_handle_log(log, state) do
    if FarmbotCore.Logger.should_log?(log.module, log.verbosity) do
      fb = %{position: %{x: nil, y: nil, z: nil}}
      location_data = Map.get(state.state_cache || %{}, :location_data, fb)

      log_without_pos = %{
        type: log.level,
        x: nil,
        y: nil,
        z: nil,
        verbosity: log.verbosity,
        major_version: log.version.major,
        minor_version: log.version.minor,
        patch_version: log.version.patch,
        # QUESTION(Connor) - Why does this need `.to_unix()`?
        # ANSWER(Connor) - because the FE needed it.
        created_at: DateTime.from_naive!(log.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
        channels: log.meta[:channels] || log.meta["channels"] || [],
        meta: %{
          assertion_passed: log.meta[:assertion_passed],
          assertion_type: log.meta[:assertion_type]
        },
        message: log.message
      }

      log = add_position_to_log(log_without_pos, location_data)
      push_bot_log(state, log)
    else
      :ok
    end
  end

  defp push_bot_log(state, log) do
    # this will add quite a bit of overhead to logging, but probably not
    # that big of a deal.
    # List extracted from:
    # https://github.com/FarmBot/Farmbot-Web-App/blob/b7f09e51e856bfca5cfedd7fef3c572bebdbe809/frontend/devices/actions.ts#L38
    if Regex.match?(~r(WPA|PSK|PASSWORD|NERVES), String.upcase(log.message)) do
      :ok
    else
      topic = "bot/#{state.username}/logs"
      MQTT.publish(state.client_id, topic, JSON.encode!(log))
      :ok
    end
  end

  defp add_position_to_log(%{} = log, %{position: %{x: x, y: y, z: z}}) do
    Map.merge(log, %{x: x, y: y, z: z})
  end
end
