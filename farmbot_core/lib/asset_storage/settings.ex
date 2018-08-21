defmodule Farmbot.Asset.Settings do
  @moduledoc """
  Responsible for turning FbosConfig and FirmwareConfig into
  local Farmbot.Config settings.
  """
  alias Farmbot.Asset.Settings.{
    FbosConfig,
    FirmwareConfig
  }

  def download_firmware(%{} = remote_fw_config) do
    local_fw_config = get_config_as_map()["hardware_params"]
    :ok = FirmwareConfig.download(remote_fw_config, local_fw_config)
  end

  def download_os(%{} = remote_os_config) do
    local_os_config = get_config_as_map()["settings"]
    :ok = FbosConfig.download(remote_os_config, local_os_config)
  end
end
