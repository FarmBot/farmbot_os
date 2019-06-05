defmodule FarmbotExt.AMQP.ConnectionWorker.Network do
  @moduledoc """
  Real-world implementation of AMQP socket IO handlers.
  """

  alias AMQP.{Basic, Channel, Queue}
  alias FarmbotCore.JSON
  @exchange "amq.topic"

  @doc "Cleanly close an AMQP channel"
  @callback close_channel(map()) :: nil
  def close_channel(chan) do
    Channel.close(chan)
  end

  @doc "Uses JWT 'bot' claim and connects to the AMQP broker / autosync channel"
  @callback maybe_connect_autosync(String.t()) :: map()
  def maybe_connect_autosync(jwt_dot_bot) do
    auto_delete = false
    chan_name = jwt_dot_bot <> "_auto_sync"
    purge? = false
    route = "bot.#{jwt_dot_bot}.sync.#"

    maybe_connect(chan_name, route, auto_delete, purge?)
  end

  @doc "Takes the 'bot' claim seen in the JWT and connects to the RPC server."
  @callback maybe_connect_celeryscript(String.t()) :: map()
  def maybe_connect_celeryscript(jwt_dot_bot) do
    auto_delete = true
    chan_name = jwt_dot_bot <> "_from_clients"
    purge? = true
    route = "bot.#{jwt_dot_bot}.from_clients"

    maybe_connect(chan_name, route, auto_delete, purge?)
  end

  defp maybe_connect(chan_name, route, auto_delete, purge?) do
    with %{} = conn <- FarmbotExt.AMQP.ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, chan_name, auto_delete: auto_delete),
         {:ok, _} <- maybe_purge(chan, chan_name, purge?),
         :ok <- Queue.bind(chan, chan_name, @exchange, routing_key: route),
         {:ok, _} <- Basic.consume(chan, chan_name, self(), no_ack: true) do
      %{conn: conn, chan: chan}
    else
      nil -> %{conn: nil, chan: nil}
      error -> error
    end
  end

  defp maybe_purge(chan, chan_name, purge?) do
    if purge? do
      Queue.purge(chan, chan_name)
    else
      {:ok, :skipped}
    end
  end

  @doc "Respond with an OK message to a CeleryScript(TM) RPC message."
  @callback rpc_reply(map(), String.t(), String.t()) :: :ok
  def rpc_reply(chan, jwt_dot_bot, label) do
    json = JSON.encode!(%{args: %{label: label}, kind: "rpc_ok"})
    Basic.publish(chan, @exchange, "bot.#{jwt_dot_bot}.from_device", json)
  end
end
