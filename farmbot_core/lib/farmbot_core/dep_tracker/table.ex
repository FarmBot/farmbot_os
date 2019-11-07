defmodule FarmbotCore.DepTracker.Table do
  use GenServer

  @doc false
  def start_link({table, _registry_name} = args) do
    GenServer.start_link(__MODULE__, args, name: table)
  end

  @doc "put data"
  def put(table, {identifier, status}) do
    GenServer.call(table, {:put, identifier, status})
  end

  @doc "get data"
  def get(table, {kind, _} = identifier) do
    :ets.match(table, {identifier, :"$2"})
    |> Enum.map(fn
      [local_id, status] -> {{kind, local_id}, status}
      other -> raise("unknown data in ets table: #{table} data: #{inspect(other)}")
    end)
  end

  def get(table, service_name) do
    :ets.match(table, {service_name, :"$2"})
    |> Enum.map(fn
      [status] -> {service_name, status}
      other -> raise("unknown data in ets table: #{table} data: #{inspect(other)}")
    end)
  end

  @impl GenServer
  def init({table, registry_name}) do
    ^table = :ets.new(table, [:named_table, read_concurrency: true])

    state = %{table: table, registry: registry_name}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:put, identifier, status}, _from, state) do
    case :ets.lookup(state.table, identifier) do
      [{^identifier, ^status}] ->
        # No change, so no notifications
        :ok

      [{^identifier, old_status}] ->
        :ets.insert(state.table, {identifier, status})
        dispatch(state, identifier, old_status, status)

      [] ->
        :ets.insert(state.table, {identifier, status})
        dispatch(state, identifier, nil, status)
    end

    {:reply, :ok, state}
  end

  defp dispatch(state, identifier, old, new) do
    kind = case identifier do
      {kind, _} -> kind
      kind -> kind
    end
    Registry.dispatch(state.registry, kind, fn entries ->
      message = {state.table, identifier, old, new}
      for {pid, _} <- entries, do: send(pid, message)
    end)
    :ok
  end
end