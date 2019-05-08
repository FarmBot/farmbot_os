defmodule FarmbotExt.AMQP.ConnectionWorker.Network do
  @moduledoc """
  Real-world implementation of AMQP socket IO handlers.
  """

  alias AMQP.{Basic, Channel, Queue}
  @exchange "amq.topic"

  @doc "Takes the 'bot' claim seen in the JWT and connects to the AMQP broker."
  @callback maybe_connect(String.t()) :: map()
  def maybe_connect(jwt_dot_bot) do
    bot = jwt_dot_bot
    auto_sync = bot <> "_auto_sync"
    route = "bot.#{bot}.sync.#"

    with %{} = conn <- FarmbotExt.AMQP.ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, auto_sync, auto_delete: false),
         :ok <- Queue.bind(chan, auto_sync, @exchange, routing_key: route),
         {:ok, _} <- Basic.consume(chan, auto_sync, self(), no_ack: true) do
      %{conn: conn, chan: chan}
    else
      nil -> %{conn: nil, chan: nil}
      error -> error
    end
  end
end
