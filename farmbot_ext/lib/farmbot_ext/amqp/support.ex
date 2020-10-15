defmodule FarmbotExt.AMQP.Support do
  alias FarmbotExt.AMQP.ConnectionWorker
  alias AMQP.{Basic, Channel, Queue}
  require FarmbotCore.Logger
  require FarmbotTelemetry

  def create_channel do
    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         %{pid: channel_pid} <- chan,
         :ok <- Basic.qos(chan, global: true) do
      Process.link(channel_pid)
      {:ok, {conn, chan}}
    else
      err -> err
    end
  end

  def create_queue(q_name) do
    with {:ok, {conn, chan}} <- create_channel(),
         {:ok, _} <- Queue.declare(chan, q_name, auto_delete: true),
         {:ok, _} <- Queue.purge(chan, q_name) do
      FarmbotTelemetry.event(:amqp, :channel_open)
      {:ok, {conn, chan}}
    else
      err -> err
    end
  end

  def handle_error(state, err, chan_name) do
    connect_fail(chan_name, err)
    Process.send_after(self(), :connect_amqp, 2000)
    {:noreply, %{state | conn: nil, chan: nil}}
  end

  def handle_termination(reason, state, name) do
    FarmbotCore.Logger.error(1, "Disconnected from #{name} channel: #{inspect(reason)}")
    if state.chan, do: ConnectionWorker.close_channel(state.chan)
  end

  def bind_and_consume(chan, queue_name, exchange, route) do
    with :ok <- Queue.bind(chan, queue_name, exchange, routing_key: route),
         {:ok, _tag} <- Basic.consume(chan, queue_name, self(), no_ack: true) do
      :ok
    else
      e -> e
    end
  end

  def create_bind_consume(queue_name, route) do
    with {:ok, {_con, chan}} = ok <- create_queue(queue_name),
         :ok <- bind_and_consume(chan, queue_name, "amq.topic", route) do
      ok
    else
      err -> err
    end
  end

  def connect_fail(chan_name, err) do
    FarmbotCore.Logger.error(1, "Failed to connect to #{chan_name} channel: #{inspect(err)}")
    FarmbotTelemetry.event(:amqp, :channel_open_error, nil, error: inspect(err))
  end
end
