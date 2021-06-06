defmodule FarmbotOS.SysCalls.FactoryReset do
  @moduledoc false
  require FarmbotCore.Logger
  alias FarmbotCore.{Asset, BotState}
  alias FarmbotExt.APIFetcher

  def factory_reset("farmbot_os") do
    FarmbotOS.System.implode("Factory reset requested by Sequence or frontend")

    :ok
  end

  def factory_reset("arduino_firmware") do
    FarmbotCore.Logger.warn(1, "Arduino Firmware going down for factory reset!")

    id = Asset.firmware_config(:id)
    if id, do: Asset.delete_firmware_config!(id)

    _ = APIFetcher.delete!(APIFetcher.client(), "/api/firmware_config")
    _ = APIFetcher.get!(APIFetcher.client(), "/api/firmware_config")

    _ =
      APIFetcher.put!(APIFetcher.client(), "/api/firmware_config", %{
        api_migrated: true
      })

    BotState.set_sync_status("maintenance")
    FarmbotOS.System.reboot("Arduino factory reset")
    :ok
  end
end
