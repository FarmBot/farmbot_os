defmodule FarmbotCore.DepTracker do
  @moduledoc """
  Subscribe to internal dependency and service status events.
  """
  alias FarmbotCore.{DepTracker, DepTracker.Table}

  @doc "Start a dep tracker instance"
  def start_link(options) do
    name = Keyword.get(options, :name, DepTracker)

    unless !is_nil(name) and is_atom(name) do
      raise ArgumentError, "expected :name to be given and to be an atom, got: #{inspect(name)}"
    end
    DepTracker.Supervisor.start_link(name)
  end

  @doc false
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, DepTracker),
      start: {DepTracker, :start_link, [opts]},
      type: :supervisor
    }
  end

  @doc "register an asset in the tracker"
  def register_asset(table \\ DepTracker, %kind{local_id: local_id}, status) do
    Table.put(table, {{kind, local_id}, status})
  end

  @doc "register a service in the tracker"
  def register_service(table \\ DepTracker, service_name, status) do
    Table.put(table, {service_name, status})
  end

  @doc """
  subscribe to asset changes from the tracker
  messages are dispatched in the shape of

      {table_name, {kind, local_id}, status}
  """
  def subscribe_asset(table \\ DepTracker, kind) do
    :ok = do_subscribe(table, kind)
    initial = get_asset(table, kind)
    for {{kind, local_id}, status} <- initial do
      send self(), {table, {kind, local_id}, nil, status}
    end
    :ok
  end

  @doc "get all current assets by kind"
  def get_asset(table \\ DepTracker, kind) do
    Table.get(table, {kind, :"$1"})
  end

  @doc """
  subscribe to service changes from the tracker
  messages are dispatched in the shape of

      {table_name, service_name, status}
  """
  def subscribe_service(table \\ DepTracker, service_name) do
    :ok = do_subscribe(table, service_name)
    initial = get_service(table, service_name)
    for {^service_name, status} <- initial do
      send self(), {table, {service_name, nil, status}}
    end
    :ok
  end

  @doc "get all current services by name"
  def get_service(table \\ DepTracker, service_name) do
    Table.get(table, service_name)
  end

  defp do_subscribe(table, name) do
    registry = DepTracker.Supervisor.registry_name(table)
    {:ok, _} = Registry.register(registry, name, nil)
    :ok
  end
end