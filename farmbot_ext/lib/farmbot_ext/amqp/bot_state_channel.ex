defmodule FarmbotExt.AMQP.BotStateChannel do
  @moduledoc """
  Publishes JSON encoded bot state updates onto an AMQP channel
  """

  use GenServer
  use AMQP
  alias AMQP.Channel

  require FarmbotCore.Logger
  alias FarmbotCore.JSON
  alias FarmbotExt.AMQP.ConnectionWorker

  alias FarmbotCore.{BotState, BotStateNG}

  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt, :cache]
  alias __MODULE__, as: State

  @doc "Forces pushing the most current state tree"
  def read_status do
    GenServer.cast(__MODULE__, :force)
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    jwt = Keyword.fetch!(args, :jwt)
    Process.flag(:sensitive, true)
    cache = BotState.subscribe()
    {:ok, %State{conn: nil, chan: nil, jwt: jwt, cache: cache}, 0}
  end

  @impl GenServer
  def terminate(reason, state) do
    FarmbotCore.Logger.error(1, "Disconnected from BotState channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: Channel.close(state.chan)
  end

  @impl GenServer
  def handle_cast(:force, state) do
    cache = BotState.fetch()
    {:noreply, %{state | cache: cache}, {:continue, :dispatch}}
  end

  @impl GenServer
  def handle_info(:timeout, %{conn: nil, chan: nil} = state) do
    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true) do
      {:noreply, %{state | conn: conn, chan: chan}, {:continue, :dispatch}}
    else
      nil ->
        {:noreply, %{state | conn: nil, chan: nil}, 5000}

      err ->
        FarmbotCore.Logger.error(1, "Failed to connect to BotState channel: #{inspect(err)}")
        {:noreply, %{state | conn: nil, chan: nil}, 1000}
    end
  end

  def handle_info(:timeout, %{chan: %{}} = state) do
    {:noreply, state, {:continue, :dispatch}}
  end

  def handle_info({BotState, change}, state) do
    cache = Ecto.Changeset.apply_changes(change)
    {:noreply, %{state | cache: cache}, {:continue, :dispatch}}
  end

  @impl GenServer
  def handle_continue(:dispatch, %{chan: nil} = state) do
    {:noreply, state, 5000}
  end

  def handle_continue(:dispatch, %{chan: %{}, cache: cache} = state) do
    json =
      cache
      |> BotStateNG.view()
      |> JSON.encode!()

    Basic.publish(state.chan, @exchange, "bot.#{state.jwt.bot}.status", json)
    {:noreply, state, 5000}
  end
end
