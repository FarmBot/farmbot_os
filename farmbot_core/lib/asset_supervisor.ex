defmodule Farmbot.AssetSupervisor do
  use Supervisor

  def list_children(kind) do
    name = Module.concat(__MODULE__, kind)
    Supervisor.which_children(name)
  end

  @doc "looks up a pid for an asset"
  def whereis_child(%kind{local_id: id}) do
    :ok = Protocol.assert_impl!(Farmbot.AssetWorker, kind)
    name = Module.concat(__MODULE__, kind)
    Supervisor.which_children(name)
    |> Enum.find_value(fn({sup_id, pid, :worker, _}) ->
      (sup_id == id) && pid
    end)
  end

  @doc "Start a process that manages an asset"
  def start_child(%kind{local_id: id} = asset) when is_binary(id) do
    :ok = Protocol.assert_impl!(Farmbot.AssetWorker, kind)
    name = Module.concat(__MODULE__, kind)
    spec = %{
      id: id,
      start: {Farmbot.AssetWorker, :start_link, [asset]},
    }
    Supervisor.start_child(name, spec)
  end

  @doc "Removes a child if it exists"
  def delete_child(%kind{local_id: id}) do
    :ok = Protocol.assert_impl!(Farmbot.AssetWorker, kind)
    name = Module.concat(__MODULE__, kind)
    case Supervisor.terminate_child(name, id) do
      :ok -> Supervisor.delete_child(name, id)
      er -> er
    end
  end

  @doc "Updates a child if it exists"
  def update_child(%kind{} = asset) do
    :ok = Protocol.assert_impl!(Farmbot.AssetWorker, kind)
    _ = delete_child(asset)
    start_child(asset)
  end

  # Non public supervisor stuff

  @doc false
  def child_spec(module) when is_atom(module) do
    id_and_name =  Module.concat(__MODULE__, module)
    %{
      id: id_and_name,
      start: {__MODULE__, :start_link, [module]},
    }
  end

  @doc false
  def start_link(module) when is_atom(module) do
    Supervisor.start_link(__MODULE__, [], name: Module.concat(__MODULE__, module))
  end

  @doc false
  def init([]) do
    Supervisor.init([], strategy: :one_for_one)
  end
end
