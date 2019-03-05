defmodule FarmbotExt.AMQP.BotStateNGTransport do
  @moduledoc """
  Publishes JSON encoded bot state fragements onto an AMQP channel
  Examples:

  if the state looks something like:
  ```
  %{location_data: %{position: %{x: 1.0, y: 0.0, z: 4.0}}}
  ```
  It would publish the following data:
  * `bot/<device_id>/status_v8/location_data.position.x` => `"1.0"`
  * `bot/<device_id>/status_v8/location_data.position.y` => `"0.0"`
  * `bot/<device_id>/status_v8/location_data_.position.z` => `"4.0"`

  One could subscribe to `bot/<device_id>/status_v8/location_data/#`
  and recieve all of those notifications.
  """

  use GenServer
  use AMQP
  alias AMQP.Channel

  require FarmbotCore.Logger
  alias FarmbotCore.JSON
  alias FarmbotExt.AMQP.ConnectionWorker

  alias FarmbotCore.BotState
  alias FarmbotCore.BotStateNG.ChangeGenerator

  # Pushes a state tree every 5 seconds for good luck.
  @default_error_retry_ms 100
  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt, :changes]
  alias __MODULE__, as: State

  @doc "Forces pushing the most current state tree"
  def force do
    GenServer.cast(__MODULE__, :force)
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    jwt = Keyword.fetch!(args, :jwt)
    Process.flag(:sensitive, true)
    changes = BotState.subscribe() |> ChangeGenerator.changes()
    {:ok, %State{conn: nil, chan: nil, jwt: jwt, changes: changes}, 0}
  end

  def terminate(reason, state) do
    FarmbotCore.Logger.error(1, "Disconnected from BotState channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: Channel.close(state.chan)
  end

  def handle_cast(:force, state) do
    changes = BotState.fetch() |> ChangeGenerator.changes()
    {:noreply, %{state | changes: changes}, 0}
  end

  def handle_info(:timeout, %{conn: nil, chan: nil} = state) do
    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true) do
      {:noreply, %{state | conn: conn, chan: chan}, 0}
    else
      nil ->
        {:noreply, %{state | conn: nil, chan: nil}, 5000}

      err ->
        FarmbotCore.Logger.error(1, "Failed to connect to BotState channel: #{inspect(err)}")
        {:noreply, %{state | conn: nil, chan: nil}, 1000}
    end
  end

  def handle_info(:timeout, %{chan: %{}} = state) do
    {:noreply, %{state | changes: []}, {:continue, state.changes}}
  end

  def handle_info({BotState, change}, state) do
    changes = (state.changes ++ change.changes) |> ChangeGenerator.changes()
    {:noreply, %{state | changes: changes}, 0}
  end

  def handle_continue([{path, value} | rest] = changes, %{chan: chan} = state) do
    path =
      path
      |> Enum.map(&to_string/1)
      |> Enum.join(".")

    json = JSON.encode!(value)

    case Basic.publish(chan, @exchange, "bot.#{state.jwt.bot}.status_v8.#{path}", json) do
      :ok ->
        {:noreply, state, {:continue, rest}}

      error ->
        msg = """
        Failed to send state value: #{path}, #{inspect(value)}
        error: #{inspect(error)}
        """

        FarmbotCore.Logger.error(1, msg)
        {:noreply, %{state | changes: changes}, @default_error_retry_ms}
    end
  end

  def handle_continue([], state), do: {:noreply, state}
end
