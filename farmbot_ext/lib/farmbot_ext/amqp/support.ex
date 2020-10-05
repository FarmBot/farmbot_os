defmodule FarmbotExt.AMQP.Support do
  alias FarmbotExt.AMQP.ConnectionWorker
  alias AMQP.{Basic, Channel}

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
end
