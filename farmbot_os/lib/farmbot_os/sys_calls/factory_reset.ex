defmodule FarmbotOS.SysCalls.FactoryReset do
  require FarmbotCore.Logger
  alias FarmbotCore.{Asset, BotState}
  alias FarmbotExt.API

  def factory_reset("farmbot_os") do
    FarmbotOS.System.factory_reset("Factory reset requested by Sequence or frontend", true)
    :ok
  end

  def factory_reset("arduino_firmware") do
    FarmbotCore.Logger.warn(1, "Arduino Firmware going down for factory reset!")

    id = Asset.firmware_config(:id)
    if id, do: Asset.delete_firmware_config!(id)

    _ = API.delete!(API.client(), "/api/firmware_config")
    _ = API.get!(API.client(), "/api/firmware_config")
    _ = API.put!(API.client(), "/api/firmware_config", %{api_migrated: true})
    BotState.set_sync_status("maintenance")
    FarmbotOS.System.reboot("Arduino factory reset")
    :ok
  end
end
