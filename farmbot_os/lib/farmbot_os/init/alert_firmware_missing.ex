defmodule FarmbotOS.Init.AlertFirmwareMissing do
  alias FarmbotCore.{Asset, Asset.Private, Asset.Private.Alert, Config}
  alias FarmbotCore.AlertHandler
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
    AlertHandler.register_up(Alert.firmware_missing(), &alert_up/1)
    AlertHandler.register_down(Alert.firmware_missing(), &alert_down/1)

    needs_flash? = Config.get_config_value(:bool, "settings", "firmware_needs_flash")

    current_fbos_config = Asset.fbos_config()
    firmware_hardware = current_fbos_config.firmware_hardware
    situation = {needs_flash?, firmware_hardware}

    case situation do
      {true, firmware_hardware} when is_binary(firmware_hardware) ->
        FarmbotCore.Logger.warn(1, "firmware needs flashed creating `firmware.missing` alert")
        Private.create_or_update_alert!(%{priority: 100, problem_tag: Alert.firmware_missing()})
        # Ignore fw/hw
        %{firmware_hardware: nil, firmware_path: nil}
        |> Asset.update_fbos_config!()
        |> Private.mark_dirty!(%{})

        :ok

      {false, firmware_hardware} when is_binary(firmware_hardware) ->
        swap_transport(Asset.fbos_config(:firmware_path))
        :ok

      {_, nil} ->
        FarmbotCore.Logger.warn(1, "firmware needs flashed- creating `firmware.missing` alert")
        Private.create_or_update_alert!(%{priority: 100, problem_tag: Alert.firmware_missing()})
        :ok
    end
  end

  # Returning :ok here will cause the alert to be cleared.
  # We don't need this callback currently, so return error.
  def alert_up(_) do
    {:error, :noop}
  end

  def alert_down(_) do
    swap_transport(Asset.fbos_config(:firmware_path))
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
  end

  defp swap_transport(tty) do
    Application.put_env(:farmbot_firmware, FarmbotFirmware, transport: UARTTransport, device: tty)
    # Swap transport on FW module.
    # Close tranpsort if it is open currently.
    _ = FarmbotFirmware.close_transport()
    :ok = FarmbotFirmware.open_transport(UARTTransport, device: tty)
  end
end
