defmodule FarmbotOS.ChangeSupervisor do
  @moduledoc """
  Supervises all database-backed records.
  """

  use Supervisor
  alias FarmbotOS.{Asset.Repo, AssetWorker}

  @doc "looks up a pid for an asset"
  def whereis_child(%kind{local_id: id}) do
    :ok = Protocol.assert_impl!(AssetWorker, kind)
    name = Module.concat(__MODULE__, kind)

    Supervisor.which_children(name)
    |> Enum.find(fn {sup_id, _pid, _type, _} ->
      sup_id == id
    end)
  end

  # TODO(Connor) does this really belong here?
  @doc "Does a GenServer call on a server"
  def cast_child(%{} = data, cast) do
    case whereis_child(data) do
      nil -> :error
      {_, pid, _, _} -> GenServer.cast(pid, cast)
    end
  end

  @doc "Start a process that manages an asset"
  def start_child(%kind{local_id: id} = asset) when is_binary(id) do
    :ok = Protocol.assert_impl!(AssetWorker, kind)
    name = Module.concat(__MODULE__, kind)
    spec = worker_spec(asset)
    Supervisor.start_child(name, spec)
  end

  @doc "Removes a child if it exists"
  def terminate_child(kind, id) when is_binary(id) do
    :ok = Protocol.assert_impl!(AssetWorker, kind)
    name = Module.concat(__MODULE__, kind)
    Supervisor.terminate_child(name, id)
  end

  @doc "Updates a child if it exists"
  def update_child(%kind{local_id: id} = asset) do
    :ok = Protocol.assert_impl!(AssetWorker, kind)
    # if the worker tracks changes, we don't want to
    # restart it.
    if AssetWorker.tracks_changes?(asset) do
      cast_child(asset, {:new_data, asset})
      {_, pid, _, _} = whereis_child(asset)
      {:ok, pid}
    else
      name = Module.concat(__MODULE__, kind)
      _ = terminate_child(kind, id)
      _ = Supervisor.delete_child(name, id)
      start_child(asset)
    end
  end

  # Non public supervisor stuff

  @doc false
  def child_spec(args) do
    module = Keyword.fetch!(args, :module)
    id_and_name = Module.concat(__MODULE__, module)

    %{
      id: id_and_name,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  @doc false
  def worker_spec(%{local_id: id, monitor: true} = asset) do
    %{
      id: id,
      start: {AssetWorker, :start_link, [asset]},
      restart: :transient
    }
  end

  @doc false
  def start_link(args) when is_list(args) do
    module = Keyword.fetch!(args, :module)

    Supervisor.start_link(__MODULE__, args,
      name: Module.concat(__MODULE__, module)
    )
  end

  @doc false
  def init(args) do
    module = Keyword.fetch!(args, :module)

    module
    |> Repo.all()
    |> Enum.filter(fn %{monitor: mon} -> mon == false end)
    |> Enum.map(&Repo.preload(&1, AssetWorker.preload(&1)))
    |> Enum.map(&worker_spec/1)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
