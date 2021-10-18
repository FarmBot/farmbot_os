defmodule FarmbotExt.API.Preloader do
  @moduledoc """
  Task to ensure download and insert or cache
  all resources stored in the API.
  """

  alias Ecto.Changeset

  require FarmbotCore.Logger
  alias FarmbotExt.API
  alias FarmbotExt.API.{Reconciler, SyncGroup}

  alias FarmbotCore.Asset.Sync

  @doc """
  Syncronous call to sync or preload assets.
  Starts with `group_0`, syncs all resources.
  """
  def preload_all() do
    with {:ok, sync_changeset} <- API.get_changeset(Sync),
         sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_0()) do
      FarmbotCore.Logger.success(3, "Successfully preloaded resources.")
      do_auto_sync(sync_changeset)
    end
  end

  defp do_auto_sync(%Changeset{} = sync_changeset) do
    FarmbotCore.Logger.busy(3, "Starting auto sync")

    with %Changeset{valid?: true} = sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_1()),
         %Changeset{valid?: true} = sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_2()),
         %Changeset{valid?: true} = sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_3()),
         %Changeset{valid?: true} <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_4()) do
      FarmbotCore.Logger.success(3, "Auto sync complete")
      :ok
    else
      error ->
        FarmbotCore.Logger.error(3, "Auto sync failed #{inspect(error)}")
        error
    end
  end
end
