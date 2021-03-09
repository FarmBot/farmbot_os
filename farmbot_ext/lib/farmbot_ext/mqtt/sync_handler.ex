defmodule FarmbotExt.MQTT.SyncHandler do
  use GenServer
  alias __MODULE__, as: State
  defstruct client_id: "NOT_SET"
  # alias FarmbotExt.MQTT
  # require Logger

  def start_link(default, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, default, opts)
  end

  def init(opts) do
    {:ok, %State{client_id: Keyword.fetch!(opts, :client_id)}}
  end

  def handle_info({:inbound, [_, _, "sync", resource, id], json}, state) do
    IO.puts("=== AUTO SYNC MESSAGE: #{inspect({resource, id})}")
    IO.puts(inspect(json))
    {:noreply, state}
  end

  def handle_info(_other, state), do: {:noreply, state}
end
