defmodule Farmbot.HTTP.SettingsWorker do
  @moduledoc """
  Watches the local database for changes to the following resources:
  * FbosConfig
  * FirmwareConfig
  * FarmwareEnv

  When a change is detected, the asset is uploaded to the API.
  """

  alias Farmbot.Asset.Settings
  import Farmbot.Config, only: [get_config_as_map: 0]
  require Farmbot.Logger
  use GenServer

  def download_all_settings do
    Farmbot.Logger.debug 3, "Syncing all settings."

    remote_fw_config = HTTP.firmware_config()
    Settings.download_firmware(remote_fw_config)

    # Make sure that the API has the correct firmware hardware.
    patch = %{"firmware_hardware" => get_config_as_map()["settings"]["firmware_hardware"]}
    remote_os_config = HTTP.update_fbos_config(patch)
    Settings.download_os(remote_os_config)

    Farmbot.Logger.debug 3, "Done syncing all settings."
    :ok
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    :ok = download_all_settings()
    {:ok, %{}}
  end
end
