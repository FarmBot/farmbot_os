defmodule FarmbotExt.API.Preloader do
  @moduledoc """
  Task to ensure download and insert or cache 
  all resources stored in the API.
  """

  alias Ecto.Changeset

  require FarmbotCore.Logger
  alias FarmbotExt.API
  alias API.{Reconciler, SyncGroup, EagerLoader}

  alias FarmbotCore.{
    Asset.Query,
    Asset.Sync
  }

  @doc """
  Syncronous call to sync or preload assets.
  Starts with `group_0` to check if `auto_sync` is enabled. If it is, 
  actually sync all resources. If it is not, preload all resources.
  """
  def preload_all() do
    # this must be called __before__ preloading.
    # if it's not, it will have been reset by the time the
    # preload completes
    first_sync? = Query.first_sync?()

    if first_sync? do
      FarmbotCore.Logger.info(2, "Farmbot doing first sync")
    end

    with {:ok, sync_changeset} <- API.get_changeset(Sync),
         sync_changeset <- Reconciler.sync_group(sync_changeset, SyncGroup.group_0()) do
      FarmbotCore.Logger.success(3, "Successfully preloaded resources.")
      maybe_auto_sync(sync_changeset, Query.auto_sync?() || first_sync?)
    end
  end

  # When auto_sync is enabled, do the full sync.
  defp maybe_auto_sync(%Changeset{} = sync_changeset, true) do
    FarmbotCore.Logger.busy(3, "Starting auto sync")

    with %Changeset{valid?: true} = sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_1()),
         %Changeset{valid?: true} = sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_2()),
         %Changeset{valid?: true} = sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_3()),
         %Changeset{valid?: true} <- Reconciler.sync_group(sync_changeset, SyncGroup.group_4()) do
      FarmbotCore.Logger.success(3, "Auto sync complete")
      :ok
    else
      error ->
        FarmbotCore.Logger.error(3, "Auto sync failed #{inspect(error)}")
        error
    end
  end

  # When auto_sync is disabled preload the sync.
  defp maybe_auto_sync(%Changeset{} = sync_changeset, false) do
    FarmbotCore.Logger.busy(3, "Preloading auto sync")
    sync = Changeset.apply_changes(sync_changeset)

    case EagerLoader.preload(sync) do
      :ok ->
        FarmbotCore.Logger.success(3, "Preloaded auto sync complete")
        :ok

      error ->
        FarmbotCore.Logger.error(3, "Preloading auto sync failed #{inspect(error)}")
        error
    end
  end
end
