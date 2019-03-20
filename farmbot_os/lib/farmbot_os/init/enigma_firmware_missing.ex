defmodule FarmbotOS.Init.EnigmaFirmwareMissing do
  alias FarmbotCore.Asset.Private
  alias FarmbotCore.EnigmaHandler
  alias FarmbotFirmware.UARTTransport

  require FarmbotCore.Logger

  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc false
  def init([]) do
    setup()
    # This is wrong. TODO: Use tasks #shipit
    :ignore
  end

  def setup() do
    EnigmaHandler.register_up("firmware.missing", &enigma_up/1)
    EnigmaHandler.register_down("firmware.missing", &enigma_down/1)

    needs_flash? = FarmbotCore.Config.get_config_value(:bool, "settings", "firmware_needs_flash")

    firmware_hardware = FarmbotCore.Asset.fbos_config(:firmware_hardware)
    situation = {needs_flash?, firmware_hardware}

    case situation do
      {true, firmware_hardware} when is_binary(firmware_hardware) ->
        FarmbotCore.Logger.warn(1, "firmware needs flashed- creating `firmware.missing` enigma")
        Private.create_or_update_enigma!(%{priority: 100, problem_tag: "firmware.missing"})

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
        Private.create_or_update_enigma!(%{priority: 100, problem_tag: "firmware.missing"})
        :ok
    end
  end

  # Returning :ok here will cause the enigma to be cleared.
  # We don't need this callback currently, so return error.
  def enigma_up(_) do
    {:error, :noop}
  end

  def enigma_down(_) do
    swap_transport(FarmbotCore.Asset.fbos_config(:firmware_path))
  end

  defp swap_transport(tty) do
    # Swap transport on FW module.
    # Close tranpsort if it is open currently.
    _ = FarmbotFirmware.close_transport()
    :ok = FarmbotFirmware.open_transport(UARTTransport, device: tty)
  end
end
