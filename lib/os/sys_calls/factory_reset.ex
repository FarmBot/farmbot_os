defmodule FarmbotOS.SysCalls.FactoryReset do
  @moduledoc false
  require FarmbotOS.Logger
  alias FarmbotOS.{Asset, BotState}
  alias FarmbotOS.APIFetcher

  def factory_reset("farmbot_os", reason) do
    FarmbotOS.System.factory_reset(reason, true)
    :ok
  end

  def factory_reset("arduino_firmware") do
    FarmbotOS.Logger.warn(1, "Arduino Firmware going down for factory reset!")

    id = Asset.firmware_config(:id)
    if id, do: Asset.delete_firmware_config!(id)

    _ = APIFetcher.delete!(APIFetcher.client(), "/api/firmware_config")
    _ = APIFetcher.get!(APIFetcher.client(), "/api/firmware_config")

    BotState.set_sync_status("maintenance")
    FarmbotOS.System.reboot("Arduino factory reset")
    :ok
  end
end
