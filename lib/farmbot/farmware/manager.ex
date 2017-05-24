defmodule Farmbot.Farmware.Manager do
  @moduledoc """
    Tracks and manages Farmware
  """
  use Farmbot.Context.Worker
  alias Farmbot.Farmware
  alias Farmware.Installer

  @typedoc false
  @type manager :: atom | pid

  @typedoc false
  @type uuid    :: binary

  @typedoc false
  @type url    :: binary

  @type state :: %{
    context: Context.t,
    farmwares: %{optional(uuid) => Farmware.t}
  }

  @doc """
    Looks up a `farmware` by its uuid or name.
  """
  @spec lookup(Context.t, uuid) :: {:ok, Farmware.t} | {:error, term}
  def lookup(%Context{farmware_manager: fwt}, uuid) do
     GenServer.call(fwt, {:lookup, uuid})
  end

  @doc """
    This exists for the sole purpose of `take-photo`.
  """
  @spec lookup_by_name(Context.t, binary) :: {:ok, Farmware.t} | {:error, term}
  def lookup_by_name(%Context{farmware_manager: fwt}, name) do
    GenServer.call(fwt, {:lookup_by_name, name})
  end

  @doc """
    Uninstall a farmware by its uuid.
  """
  @spec uninstall(Context, uuid) :: :ok | {:error, term}
  def uninstall(%Context{farmware_manager: fwt} = ctx, uuid) do
    try do
      case lookup(ctx, uuid) do
        {:ok, %Farmware{} = fw} ->
          Installer.uninstall!(ctx, fw)
          GenServer.call(fwt, {:unregister, uuid})
        {:error, reason}        -> raise reason
      end
    rescue
      e -> {:error, e}
    end
  end

  @doc """
    Same as `uninstall/2` but raises if errors.
  """
  @spec uninstall!(Context.t, uuid) :: :ok | no_return
  def uninstall!(%Context{} = ctx, uuid) do
    case uninstall(ctx, uuid) do
      :ok -> :ok
      {:error, e} -> raise e
    end
  end

  @doc """
    Install a farmware from the internets.
  """
  @spec install(Context.t, url) :: :ok | {:error, term}
  def install(%Context{farmware_manager: fwt} = ctx, url) do
    try do
      %Farmware{} = fw = Installer.install!(ctx, url)
      GenServer.call(fwt, {:register, fw.uuid, fw})
    rescue
      e -> {:error, e}
    end
  end

  @doc """
    Same as `install/2` but raise if any errors.
  """
  def install!(%Context{} = ctx, url) do
    case install(ctx, url) do
      :ok -> :ok
      {:error, e} -> raise e
    end
  end

  @doc """
    Updates a Farmware.
  """
  def update(%Context{} = ctx, uuid) do
    try do
      do_update(ctx, uuid)
    rescue
      e -> {:error, e}
    end
  end

  @doc """
    Same as `update/2` but raises if any errors.
  """
  def update!(%Context{} = ctx, uuid), do: do_update(ctx, uuid)

  defp do_update(%Context{} = ctx, uuid) do
    {:ok, %Farmware{url: old_url}} = lookup(ctx, uuid)
    :ok = uninstall!(ctx, uuid)
    :ok = install!(ctx, old_url)
  end

  ## GenServer stuff

  def init(ctx) do
    state = %{
      context: ctx,
      farmwares: %{}
    }
    {:ok, state}
  end

  def handle_call({:lookup, uuid}, _, state) do
    reply     = fetch_fw(state, uuid)
    {:reply, reply, state}
  end

  def handle_call({:lookup_by_name, name}, _, state) do
    farmwares = state.farmwares
    reply = Enum.find_value(farmwares, {:error, :not_found},
      fn({_uuid, %Farmware{name: fw_name} = fw}) ->
        if fw_name == name do
          {:ok, fw}
        end
      end)
    {:reply, reply, state}
  end


  def handle_call({:register, uuid, %Farmware{} = fw}, _, state) do
    new_fws = Map.put(state, uuid, fw)
    reply   = :ok
    {:reply, reply, %{ state | farmwares: new_fws}}
  end

  def handle_call({:unregister, uuid}, _, state) do
    reply   = fetch_fw(state, uuid)
    new_fws = Map.delete(state.farmwares, uuid)
    {:reply, reply, %{state | farmwares: new_fws}}
  end


  @spec fetch_fw(state, uuid) :: {:ok, Farmware.t} | {:error, :not_found}
  defp fetch_fw(state, uuid) do
    case state.farmwares[uuid] do
      nil              -> {:error, :not_found}
      %Farmware{} = fw -> {:ok, fw}
    end
  end
end
