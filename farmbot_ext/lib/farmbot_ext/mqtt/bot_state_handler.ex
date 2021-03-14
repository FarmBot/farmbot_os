defmodule FarmbotExt.MQTT.BotStateChannel do
  @moduledoc """
  Publishes JSON encoded bot state updates onto an MQTT channel
  """

  alias FarmbotCore.{BotState, BotStateNG, JSON}
  alias FarmbotExt.MQTT
  require FarmbotTelemetry
  use GenServer

  defstruct [:client_id, :username, :cache]
  alias __MODULE__, as: State

  @doc "Forces pushing the most current state tree"
  def read_status(name \\ __MODULE__) do
    GenServer.cast(name, :reload)
  end

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    state = %State{
      client_id: Keyword.fetch!(args, :client_id),
      username: Keyword.fetch!(args, :username),
      cache: BotState.subscribe()
    }

    {:ok, state}
  end

  def handle_cast(:reload, state) do
    {:noreply, broadcast!(%{state | cache: BotState.fetch()})}
  end

  def handle_info({BotState, change}, state) do
    cache = Ecto.Changeset.apply_changes(change)
    {:noreply, broadcast!(%{state | cache: cache})}
  end

  def handle_info(other, state) do
    IO.inspect("UNEXPECTED HANDLE_INFO: #{inspect(other)}")
    {:noreply, state}
  end

  defp broadcast!(state) do
    IO.puts("Triggering state update.")

    json =
      state.cache
      |> BotStateNG.view()
      |> JSON.encode!()

    topic = "bot/#{state.username}/status"
    MQTT.publish(state.client_id, topic, json)
    state
  end
end
