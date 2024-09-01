defmodule FarmbotOS.MQTT.BotStateHandler do
  @moduledoc """
  Publishes JSON encoded bot state updates onto an MQTT channel
  """

  alias FarmbotOS.{BotState, BotStateNG, JSON}
  alias FarmbotOS.MQTT
  require FarmbotTelemetry
  require Logger
  use GenServer

  defstruct client_id: "NOT_SET",
            username: "NOT_SET",
            last_broadcast: nil

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
    BotState.subscribe()

    state = %State{
      client_id: Keyword.fetch!(args, :client_id),
      username: Keyword.fetch!(args, :username)
    }

    {:ok, state}
  end

  def handle_cast(:reload, state) do
    {:noreply, broadcast!(state, true)}
  end

  def handle_info({BotState, _}, state) do
    {:noreply, broadcast!(state)}
  end

  def handle_info(other, state) do
    Logger.info("UNEXPECTED HANDLE_INFO: #{inspect(other)}")
    {:noreply, state}
  end

  def broadcast!(%{last_broadcast: last} = state, force \\ false) do
    next = BotState.fetch()

    if next != last || force do
      json =
        next
        |> BotStateNG.view()
        |> JSON.encode!()

      topic = "bot/#{state.username}/status"
      MQTT.publish(state.client_id, topic, json)
      %{state | last_broadcast: next}
    else
      state
    end
  end
end
