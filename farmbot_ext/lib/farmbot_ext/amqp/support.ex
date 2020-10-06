defmodule FarmbotExt.AMQP.Support do
  alias FarmbotExt.AMQP.ConnectionWorker
  alias AMQP.{Basic, Channel, Queue}

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
      {:ok, {conn, chan}}
    else
      err -> err
    end
  end
end
