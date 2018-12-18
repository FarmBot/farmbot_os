defmodule Farmbot.Asset.Sync do
  alias Farmbot.Asset.{
    Repo,
    SyncCmd
  }
  require Farmbot.Logger
  require Logger
  import Ecto.Query, warn: false

  def sync(verbosity \\ 1) do
    Farmbot.Logger.info(verbosity, "Syncing")
    before_sync = Repo.snapshot()

    after_sync = Repo.snapshot()
    diff = Repo.Snapshot.diff(before_sync, after_sync)
    dispatch_sync(diff)
  end

  @doc """
  Register a sync message from an external source.
  This is like a snippit of the changes that have happened.
  `sync_cmd`s should only be applied on `sync`ing.
  `sync_cmd`s are _not_ a source of truth for transactions that have been applied.
  Use the `Farmbot.Asset.Registry` for these types of events.
  """
  def register_sync_cmd(remote_id, kind, body) when is_binary(kind) do
    # Make sure to raise if this isn't valid.
    _ = kind_to_module(kind)
    new_sync_cmd(remote_id, kind, body)
    |> SyncCmd.changeset()
    |> Repo.insert!()
  end

  @doc "Destroy all sync cmds locally."
  def destroy_all_sync_cmds do
    Repo.delete_all(SyncCmd)
  end

  @doc "Returns all sync cmds stored locally."
  def all_sync_cmds, do: Repo.all(SyncCmd)

  @doc "Delete a single cmd."
  def destroy_sync_cmd(%SyncCmd{id: nil} = cmd), do: {:ok, cmd}
  def destroy_sync_cmd(%SyncCmd{} = cmd), do: Repo.delete(cmd)

  defp apply_sync_cmd(%SyncCmd{} = cmd) do
    mod = kind_to_module(kind)
    Farmbot.Logger.debug(3, "Syncing #{cmd.kind}")
    try do
      do_apply_sync_cmd(cmd)
    rescue
      e ->
        Farmbot.Logger.error(1, "Error syncing: #{mod}: #{Exception.message(e)}")
    end
    destroy_sync_cmd(cmd)
  end

  # When `body` is nil, it means an object was deleted.
  defp do_apply_sync_cmd(%{body: nil, remote_id: id, kind: kind}) do
    mod = kind_to_module(kind)
    case Repo.one(from m in mod, where: m.id == ^id) do
      nil ->
        :ok

      existing ->
        Repo.delete!(existing)
        :ok
    end
  end

  defp do_apply_sync_cmd(%{body: obj, remote_id: id, kind: kind}) do
    not_struct = strip_struct(obj)
    mod = kind_to_module(kind)
    # We need to check if this object exists in the database.
    case Repo.one(from m in mod, where: m.id == ^id) do
      # If it does not, just return the newly created object.
      nil ->
        change = mod.changeset(struct(mod, not_struct), not_struct)
        Repo.insert!(change)
        :ok
      # if there is an existing record, copy the ecto  meta from the old
      # record. This allows `insert_or_update` to work properly.
      existing ->
        existing
        |> Ecto.Changeset.change(not_struct)
        |> Repo.update!()
        :ok
    end
  end

  defp strip_struct(%{__struct__: _, __meta__: _} = struct),
    do: Map.from_struct(struct) |> Map.drop([:__struct__, :__meta__])
  defp strip_struct(%{} = already_map), do: already_map

  defp new_sync_cmd(remote_id, kind, body)
    when is_integer(remote_id) when is_binary(kind)
  do
    _mod = Module.concat(["Farmbot", "Asset", kind])
    struct(SyncCmd, %{remote_id: remote_id, kind: kind, body: body})
  end

  defp kind_to_module(kind) do
    mod = Module.concat(["Farmbot", "Asset", kind])
    if !Code.ensure_loaded?(mod), do: raise("Unknown kind: #{kind}")
    mod
  end

  defp dispatch_sync(diff) do
    for deletion <- diff.deletions do
      Farmbot.Registry.dispatch(__MODULE__, {:deletion, deletion})
    end

    for update <- diff.updates do
      Farmbot.Registry.dispatch(__MODULE__, {:update, update})
    end

    for addition <- diff.additions do
      Farmbot.Registry.dispatch(__MODULE__, {:addition, addition})
    end
  end
end
