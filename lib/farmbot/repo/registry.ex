defmodule Farmbot.Repo.Registry do
  @moduledoc "Event system for receiving inserts, updates, or deletions of assets."
  use GenServer
  alias Farmbot.Repo.Snapshot

  @doc false
  def dispatch(%Snapshot.Diff{} = diff) do
    Enum.each(diff.deletions, fn(deletion) ->
      GenServer.cast(__MODULE__, {:deletion, deletion})
    end)

    Enum.each(diff.updates, fn(update) ->
      GenServer.cast(__MODULE__, {:update, update})
    end)

    Enum.each(diff.additions, fn(addition) ->
      GenServer.cast(__MODULE__, {:addition, addition})
    end)
    :ok
  end

  @doc """
  Subscribing for events will come in the shape of:
  `{Farmbot.Repo.Registry, action, module, data}`
  where:
  * `action` - will be one of `:addition`, `:deletion`, `:update`.
  * `module` - will be one of the `syncable` modules with the API.
  * `data`   - will be the actual object that was applied.
  """
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
    msg = {__MODULE__, action, object.__struct__, object}
    # IO.puts "Dispatching: #{inspect msg}"
    Enum.each(state.subscribers, fn(pid) ->
      send(pid, msg)
    end)
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _}, state) do
    {:noreply, %{state | subscribers: List.delete(state.subscribers, pid)}}
  end
end
