defmodule FarmbotExt.AMQP.BotStateChannel do
  @moduledoc """
  Publishes JSON encoded bot state updates onto an AMQP channel
  """

  use GenServer

  require FarmbotCore.Logger
  require FarmbotTelemetry
  alias FarmbotCore.BotState
  alias FarmbotExt.AMQP.Support
  alias FarmbotExt.AMQP.BotStateChannelSupport

  defstruct [:conn, :chan, :jwt, :cache]
  alias __MODULE__, as: State

  @doc "Forces pushing the most current state tree"
  def read_status(name \\ __MODULE__) do
    GenServer.cast(name, :force)
  end

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @impl GenServer
  def init(args) do
    jwt = Keyword.fetch!(args, :jwt)
    cache = BotState.subscribe()
    {:ok, %State{conn: nil, chan: nil, jwt: jwt, cache: cache}, 0}
  end

  @impl GenServer
  def handle_info(:timeout, %{conn: nil, chan: nil} = state) do
    result = Support.create_channel()
    do_connect(result, state)
  end

  def handle_info(:timeout, %{chan: %{}} = state) do
    {:noreply, state, {:continue, :dispatch}}
  end

  def handle_info({BotState, change}, state) do
    cache = Ecto.Changeset.apply_changes(change)
    {:noreply, %{state | cache: cache}, {:continue, :dispatch}}
  end

  @impl GenServer
  def handle_cast(:force, state) do
    cache = BotState.fetch()
    {:noreply, %{state | cache: cache}, {:continue, :dispatch}}
  end

  @impl GenServer
  def handle_continue(:dispatch, %{chan: nil} = state) do
    FarmbotExt.Time.no_reply(state, 5000)
  end

  def handle_continue(:dispatch, %{chan: chan, cache: cache} = state) do
    BotStateChannelSupport.broadcast_state(chan, state.jwt.bot, cache)
    FarmbotExt.Time.no_reply(state, 5000)
  end

  @impl GenServer
  def terminate(r, s), do: Support.handle_termination(r, s, "BotState")

  # Case: Connect OK
  def do_connect({:ok, {conn, chan}}, state) do
    {:noreply, %{state | conn: conn, chan: chan}, {:continue, :dispatch}}
  end

  # Case: No connectivity?
  def do_connect(nil, state) do
    FarmbotExt.Time.no_reply(%{state | conn: nil, chan: nil}, 5000)
  end

  # Case: All other errors
  def do_connect(error, state) do
    Support.connect_fail("BotState", error)
    FarmbotExt.Time.no_reply(%{state | conn: nil, chan: nil}, 1000)
  end
end
