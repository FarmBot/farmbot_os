defmodule FarmbotCore.DepTracker.Logger do
  alias FarmbotCore.DepTracker
  require Logger
  use GenServer

  @doc false
  def child_spec(args) do
    %{
      id: name(args),
      start: {FarmbotCore.DepTracker.Logger, :start_link, [args]},
    }
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: name(args)])
  end

  defp name({table, [service: service_name]}) do
    Module.concat([__MODULE__, table, service_name])
  end

  defp name({table, [asset: kind]}) do
    Module.concat([__MODULE__, table, kind])
  end

  def init({table, [service: service_name]}) do
    :ok = DepTracker.subscribe_service(table, service_name)
    {:ok, %{service: service_name, table: table}}
  end

  def init({table, [asset: kind]}) do
    :ok = DepTracker.subscribe_asset(table, kind)
    {:ok, %{asset: kind, table: table}}
  end

  def handle_info({table, {kind, local_id}, old_status, new_status}, %{asset: kind, table: table} = state) do
    Logger.info """
    #{inspect(table)} asset status change:
    #{kind} local_id = #{local_id}
    #{kind} #{inspect(old_status)} => #{inspect(new_status)}
    """
    {:noreply, state}
  end

  def handle_info({table, service, old_status, new_status}, %{service: service, table: table} = state) do
    Logger.info """
    #{inspect(table)} service status change:
    #{service} #{inspect(old_status)} => #{inspect(new_status)}
    """
    {:noreply, state}
  end
end