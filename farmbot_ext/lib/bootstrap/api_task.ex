defmodule Farmbot.Bootstrap.APITask do
  @moduledoc """
  Task to ensure Farmbot has synced:
    * Farmbot.Asset.Device
    * Farmbot.Asset.FbosConfig
    * Farmbot.Asset.FirmwareConfig
  """
  require Farmbot.Logger
  import Farmbot.Config, only: [get_config_value: 3, update_config_value: 4]
  alias Farmbot.API
  alias Farmbot.Asset.{Repo, Device, FbosConfig, FirmwareConfig}

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :sync_all, []},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc false
  def sync_all() do
    _ = sync_device()
    _ = sync_fbos_config()
    _ = sync_firmware_config()

    if get_config_value(:bool, "settings", "auto_sync") do
      try do
        API.Reconciler.sync()
      catch
        _, _ ->
          Farmbot.Logger.error(1, "Faild to bootup sync.")
      end
    end

    :ignore
  end

  def sync_device do
    device = Repo.one(Device) || Device

    API.get_changeset(device)
    |> Repo.insert_or_update!()
    |> device_to_config_storage()
  end

  def device_to_config_storage(%Device{timezone: tz} = device) do
    update_config_value(:string, "settings", "timezone", tz)
    device
  end

  def sync_fbos_config do
    fbos_config = Repo.one(FbosConfig) || FbosConfig

    API.get_changeset(fbos_config)
    |> Repo.insert_or_update!()
    |> fbos_config_to_config_storage()
  end

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
    config
  end

  def sync_firmware_config do
    firmware_config = Repo.one(FirmwareConfig) || FirmwareConfig

    API.get_changeset(firmware_config)
    |> Repo.insert_or_update!()
  end
end
