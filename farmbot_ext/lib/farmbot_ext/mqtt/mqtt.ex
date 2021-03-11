defmodule FarmbotExt.MQTT do
  require Logger

  use Tortoise.Handler

  defstruct client_id: "NOT_SET", connection_status: :down, supervisor: nil

  alias FarmbotExt.MQTT.{
    PingHandler,
    RPCHandler,
    SyncHandler,
    TerminalHandler,
    TopicSupervisor
  }

  alias __MODULE__, as: State

  def publish(client_id, topic, payload, opts \\ [qos: 0]) do
    result = Tortoise.publish(client_id, topic, payload, opts)

    if result != :ok do
      notice(result, "⛆ B ⛆ A ⛆ D ⛆ M ⛆ Q ⛆ T ⛆ T")
    end

    # Returns `:ok` or an `{:error, :tuple}`
    result
  end

  def init(args) do
    client_id = Keyword.fetch!(args, :client_id)

    opts = [
      client_id: client_id,
      parent: self(),
      username: Keyword.fetch!(args, :username)
    ]

    {:ok, supervisor} = TopicSupervisor.start_link(opts)
    {:ok, %State{client_id: client_id, supervisor: supervisor}}
  end

  def handle_message([_, _, "ping", _] = topic, payload, s) do
    forward_message(PingHandler, {topic, payload})
    {:ok, s}
  end

  def handle_message([_, _, "terminal_input"] = topic, payload, s) do
    forward_message(TerminalHandler, {topic, payload})
    {:ok, s}
  end

  def handle_message([_, _, "from_clients"] = topic, payload, s) do
    forward_message(RPCHandler, {topic, payload})
    {:ok, s}
  end

  def handle_message([_, _, "sync" | _] = topic, payload, s) do
    forward_message(SyncHandler, {topic, payload})
    {:ok, s}
  end

  def handle_message(topic, payl, state) do
    notice({topic, payl}, "Unhandled MQTT message")
    {:ok, state}
  end

  def forward_message(nil, msg) do
    Logger.debug("Dropped message: #{inspect(msg)}")
  end

  def forward_message(pid, {topic, message}) when is_pid(pid) do
    if Process.alive?(pid), do: send(pid, {:inbound, topic, message})
  end

  def forward_message(mod, {topic, message}) do
    forward_message(Process.whereis(mod), {topic, message})
  end

  def connection(:up, state) do
    resubscribe(state)
    {:ok, %{state | connection_status: :up}}
  end

  def connection(status, state) do
    {:ok, %{state | connection_status: status}}
  end

  def resubscribe(%{client_id: client_id}) do
    meta_data = Tortoise.Connection.subscriptions(client_id)
    Tortoise.Connection.subscribe(client_id, meta_data.topics)
  end

  def subscription(_stat, _filter, state) do
    {:ok, state}
  end


  def notice(payl, label) do
    IO.inspect(payl, label: "⛆⛆⛆⛆ " <> label)
  end
end
