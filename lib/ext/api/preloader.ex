defmodule FarmbotOS.API.Preloader do
  @moduledoc """
  Task to ensure download and insert or cache
  all resources stored in the API.
  """

  alias Ecto.Changeset

  require FarmbotOS.Logger
  alias FarmbotOS.API
  alias FarmbotOS.API.{Reconciler, SyncGroup}

  alias FarmbotOS.Asset.Sync

  @doc """
  Synchronous call to sync or preload assets.
  Starts with `group_0`, syncs all resources.
  """
  def preload_all() do
    with {:ok, sync_changeset} <- API.get_changeset(Sync),
         sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_0()) do
      do_auto_sync(sync_changeset)
    end
  end

  defp do_auto_sync(%Changeset{} = sync_changeset) do
    FarmbotOS.Logger.busy(3, "Starting auto sync")

    with %Changeset{valid?: true} = sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_1()),
         %Changeset{valid?: true} = sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_2()),
         %Changeset{valid?: true} = sync_changeset <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_3()),
         %Changeset{valid?: true} <-
           Reconciler.sync_group(sync_changeset, SyncGroup.group_4()) do
      FarmbotOS.Logger.success(3, "Auto sync complete")
      :ok
    else
      error ->
        FarmbotOS.Logger.error(3, "Auto sync failed #{inspect(error)}")
        error
    end
  end
end
