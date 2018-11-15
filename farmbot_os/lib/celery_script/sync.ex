defmodule Farmbot.OS.IOLayer.Sync do
  @moduledoc false
  require Farmbot.Logger
  alias Farmbot.{Asset.Repo, Asset.Sync, API}
  alias API.{Reconciler, SyncGroup}
  alias Ecto.{Changeset, Multi}

  def execute(_args, _body) do
    Farmbot.Logger.busy(3, "Syncing")
    sync_changeset = API.get_changeset(Sync)
    sync = Changeset.apply_changes(sync_changeset)
    multi = Multi.new()

    :ok = Farmbot.BotState.set_sync_status("syncing")

    with {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_1()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_2()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_3()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_4()) do
      Multi.insert(multi, :syncs, sync_changeset)
      |> Repo.transaction()

      Farmbot.Logger.success(3, "Synced")
      :ok = Farmbot.BotState.set_sync_status("synced")
      :ok
    else
      error ->
        :ok = Farmbot.BotState.set_sync_status("sync_error")
        {:error, inspect(error)}
    end
  end
end
