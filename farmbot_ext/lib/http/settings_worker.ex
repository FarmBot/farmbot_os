defmodule Farmbot.HTTP.SettingsWorker do
  @moduledoc """
  Watches the local database for changes to the following resources:
  * FbosConfig
  * FirmwareConfig
  * FarmwareEnv

  When a change is detected, the asset is uploaded to the API.
  """

  alias Farmbot.HTTP

  alias HTTP.SettingsWorker.{
    FirmwareConfig,
    FbosConfig,
    FarmwareEnv
  }

  import Farmbot.Config, only: [get_config_as_map: 0]
  require Farmbot.Logger

  use GenServer

  def sync_all_settings do
    Farmbot.Logger.debug 3, "Syncing all settings."

    remote_fw_config = HTTP.firmware_config()
    local_fw_config = get_config_as_map["hardware_params"]
    :ok = FirmwareConfig.sync(remote_fw_config, local_fw_config)

    remote_os_config = HTTP.fbos_config()
    local_os_config = get_config_as_map["settings"]
    :ok = FbosConfig.sync(remote_os_config, local_os_config)

    remote_fwe_config = HTTP.farmware_envs()
    local_fwe_config = Farmbot.Asset.all_farmware_envs
    :ok = FarmwareEnv.sync(remote_fwe_config, local_fwe_config)

    Farmbot.Logger.debug 3, "Done syncing all settings."    
    :ok
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    :ok = sync_all_settings()
    Farmbot.Registry.subscribe()
    {:ok, %{}}
  end

  defp str_to_atom({k, v}), do: {String.to_atom(to_string(k)), v}

end
