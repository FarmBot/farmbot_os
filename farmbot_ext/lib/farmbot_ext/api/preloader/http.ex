defmodule FarmbotExt.API.Preloader.HTTP do
  alias Ecto.{Changeset, Multi}

  require FarmbotCore.Logger
  alias FarmbotExt.API
  alias API.{Reconciler, SyncGroup, EagerLoader}

  alias FarmbotCore.{
    Asset,
    Asset.Repo,
    Asset.Sync
  }

  @behaviour FarmbotExt.API.Preloader

  @doc """
  Syncronous call to sync or preload assets.
  Starts with `group_0` to check if `auto_sync` is enabled. If it is, 
  actually sync all resources. If it is not, preload all resources.
  """
  def preload_all() do
    sync_changeset = API.get_changeset(Sync)
    sync = Changeset.apply_changes(sync_changeset)

    multi = Multi.new()

    with {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_0()),
         {:ok, _} <- Repo.transaction(multi) do
      auto_sync_change =
        Enum.find_value(multi.operations, fn {{key, _id}, {:changeset, change, []}} ->
          key == :fbos_configs && Changeset.get_change(change, :auto_sync)
        end)

      FarmbotCore.Logger.success(3, "Successfully synced bootup resources.")

      :ok = maybe_auto_sync(sync_changeset, auto_sync_change || Asset.fbos_config().auto_sync)
    end
  end

  # When auto_sync is enabled, do the full sync.
  defp maybe_auto_sync(sync_changeset, true) do
    FarmbotCore.Logger.busy(3, "bootup auto sync")
    sync = Changeset.apply_changes(sync_changeset)
    multi = Multi.new()

    with {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_1()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_2()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_3()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_4()) do
      Multi.insert(multi, :syncs, sync_changeset)
      |> Repo.transaction()

      FarmbotCore.Logger.success(3, "bootup auto sync complete")
    else
      error -> FarmbotCore.Logger.error(3, "bootup auto sync failed #{inspect(error)}")
    end

    :ok
  end

  # When auto_sync is disabled preload the sync.
  defp maybe_auto_sync(sync_changeset, false) do
    FarmbotCore.Logger.busy(3, "preloading sync")
    sync = Changeset.apply_changes(sync_changeset)
    EagerLoader.preload(sync)
    FarmbotCore.Logger.success(3, "preloaded sync ok")
    :ok
  end
end
