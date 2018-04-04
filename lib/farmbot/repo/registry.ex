defmodule Farmbot.Repo.Registry do
  @moduledoc "Event system for receiving inserts, updates, or deletions of assets."
  use GenServer
  alias Farmbot.Repo.Snapshot

  @doc false
  def dispatch(%Snapshot.Diff{} = diff) do
    Enum.each(diff.additions, fn(addition) ->
      GenServer.cast(__MODULE__, {:addition, addition})
    end)

    Enum.each(diff.deletions, fn(deletion) ->
      GenServer.cast(__MODULE__, {:deletion, deletion})
    end)

    Enum.each(diff.updates, fn(update) ->
      GenServer.cast(__MODULE__, {:update, update})
    end)
    :ok
  end

  @doc "Subscribe for events."
  def subscribe do
    :ok = GenServer.call(__MODULE__, :subscribe)
    Farmbot.Repo.snapshot()
    |> Farmbot.Repo.Snapshot.diff()
    |> dispatch()
  end

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:ok, %{subscribers: []}}
  end

  def handle_call(:subscribe, {pid, _}, state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | subscribers: [pid | state.subscribers]}}
  end

  def handle_cast({action, object}, state) do
    Enum.each(state.subscribers, fn(pid) ->
      send(pid, {__MODULE__, action, object.__struct__, object})
    end)
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _}, state) do
    {:noreply, %{state | subscribers: List.delete(state.subscribers, pid)}}
  end
end
