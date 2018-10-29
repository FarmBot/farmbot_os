defmodule Farmbot.Bootstrap.APITask do
  @moduledoc """
  Task to ensure Farmbot has synced:
    * Farmbot.Asset.Device
    * Farmbot.Asset.FbosConfig
    * Farmbot.Asset.FirmwareConfig
  """
  alias Ecto.{Changeset, Multi}

  require Farmbot.Logger
  import Farmbot.Config, only: [get_config_value: 3, update_config_value: 4]
  alias Farmbot.API
  alias API.{Reconciler, SyncGroup, EagerLoader}

  alias Farmbot.Asset.{
    Repo,
    Sync,
    Device,
    FbosConfig
    # FirmwareConfig
  }

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :sync_all, []},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  @doc false
  def sync_all() do
    sync_changeset = API.get_changeset(Sync)
    sync = Changeset.apply_changes(sync_changeset)

    multi = Multi.new()

    with {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_0()),
         {:ok, r} <- Repo.transaction(multi) do
      [%{id: device_id}] = sync.devices
      [%{id: fbos_config_id}] = sync.fbos_configs
      # [%{id: firmware_config_id}] = sync.firmware_configs
      :ok = device_to_config_storage(r[{:devices, device_id}])
      :ok = fbos_config_to_config_storage(r[{:fbos_configs, fbos_config_id}])
      # :ok = firmware_config_to_config_storage(r[{:firmware_configs, firmware_config_id}])
      Farmbot.Logger.success(3, "Successfully synced bootup resources.")

      :ok = maybe_auto_sync(sync_changeset, get_config_value(:bool, "settings", "auto_sync"))
    end

    :ignore
  end

  # When auto_sync is enabled, do the full sync.
  defp maybe_auto_sync(sync_changeset, true) do
    Farmbot.Logger.busy(3, "bootup auto sync")
    sync = Changeset.apply_changes(sync_changeset)
    multi = Multi.new()

    with {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_1()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_2()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_3()),
         {:ok, multi} <- Reconciler.sync_group(multi, sync, SyncGroup.group_4()) do
      Multi.insert(multi, :syncs, sync_changeset)
      |> Repo.transaction()

      Farmbot.Logger.success(3, "bootup auto sync complete")
    else
      error -> Farmbot.Logger.error(3, "bootup auto sync failed #{inspect(error)}")
    end

    :ok
  end

  # When auto_sync is disabled preload the sync.
  defp maybe_auto_sync(sync_changeset, false) do
    Farmbot.Logger.busy(3, "preloading sync")
    sync = Changeset.apply_changes(sync_changeset)
    EagerLoader.preload(sync)
    Farmbot.Logger.success(3, "preloaded sync ok")
    :ok
  end

  def device_to_config_storage(nil), do: :ok

  def device_to_config_storage(%Device{timezone: tz} = _device) do
    update_config_value(:string, "settings", "timezone", tz)
    :ok
  end

  def fbos_config_to_config_storage(nil), do: :ok

  def fbos_config_to_config_storage(%FbosConfig{} = config) do
    update_config_value(
      :bool,
      "settings",
      "arduino_debug_messages",
      config.arduino_debug_messages
    )

    update_config_value(:bool, "settings", "auto_sync", config.auto_sync)
    update_config_value(:bool, "settings", "beta_opt_in", config.beta_opt_in)
    update_config_value(:bool, "settings", "disable_factory_reset", config.disable_factory_reset)
    update_config_value(:string, "settings", "firmware_hardware", config.firmware_hardware)
    update_config_value(:bool, "settings", "firmware_input_log", config.firmware_input_log)
    update_config_value(:bool, "settings", "firmware_output_log", config.firmware_output_log)

    update_config_value(
      :float,
      "settings",
      "network_not_found_timer",
      config.network_not_found_timer && config.network_not_found_timer / 1
    )

    update_config_value(:bool, "settings", "os_auto_update", config.os_auto_update)
    update_config_value(:bool, "settings", "sequence_body_log", config.sequence_body_log)
    update_config_value(:bool, "settings", "sequence_complete_log", config.sequence_complete_log)
    update_config_value(:bool, "settings", "sequence_init_log", config.sequence_init_log)
    :ok
  end
end
