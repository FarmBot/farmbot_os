defmodule FarmbotOS.Init.EnigmaFirmwareMissing do
  alias FarmbotCore.Asset.Private
  alias FarmbotCore.EnigmaHandler
  alias FarmbotFirmware.UARTTransport

  require FarmbotCore.Logger

  def setup() do
    EnigmaHandler.register_up("firmware.missing", &enigma_up/1)
    EnigmaHandler.register_down("firmware.missing", &enigma_down/1)

    needs_flash? =
      FarmbotCore.Config.get_config_value(:string, "settings", "firmware_needs_flash")

    firmware_hardware = FarmbotCore.Asset.fbos_config(:firmware_hardware)
    situation = {needs_flash?, firmware_hardware}

    case situation do
      {true, firmware_hardware} when is_binary(firmware_hardware) ->
        FarmbotCore.Logger.warn(1, "firmware needs flashed- creating `firmware.missing` enigma")
        Private.new_enigma(%{priority: 100, problem_tag: "firmware.missing"})

        # Ignore fw/hw
        FarmbotCore.Asset.update_fbos_config!(%{
          firmware_hardware: nil,
          firmware_path: nil
        })

        :ok

      {false, firmware_hardware} when is_binary(firmware_hardware) ->
        swap_transport(FarmbotCore.Asset.fbos_config(:firmware_path))

      {_, nil} ->
        FarmbotCore.Logger.warn(1, "firmware needs flashed- creating `firmware.missing` enigma")
        Private.new_enigma(%{priority: 100, problem_tag: "firmware.missing"})
        :ok
    end
  end

  def enigma_up(_) do
    :ok
  end

  def enigma_down(_) do
    swap_transport(FarmbotCore.Asset.fbos_config(:firmware_path))
  end

  def swap_transport(tty) do
    # Swap transport on FW module.
    # Close tranpsort if it is open currently.
    _ = FarmbotFirmware.close_transport()
    :ok = FarmbotFirmware.open_transport(UARTTransport, device: tty)
  end
end
