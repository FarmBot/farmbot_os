defmodule Scratch do
  require FarmbotCore.Logger
  require Logger
  alias FarmbotFirmware
  alias FarmbotCore.{Asset.FirmwareConfig, FirmwareSideEffects}
  alias FarmbotFirmware.{UARTTransport, StubTransport}

  def emergency_lock do
    _ = FarmbotFirmware.command({:command_emergency_lock, []})
    :ok
  end

  def stub_flash_swap do
    stub()
    do_flash_swap()
  end

  defp do_flash_swap do
    Logger.debug("refresh now")

    case flash() do
      {_, 0} ->
        swap_transport()

      error ->
        Logger.error("error flashing: #{inspect(error)}")
        do_flash_swap()
    end
  end

  def flash do
    FarmbotOS.Platform.Target.FirmwareReset.reset()

    Application.app_dir(:farmbot_firmware, ["priv", "farmduino_exp_v20.hex"])
    |> Avrdude.flash("/dev/ttyAMA0")
  end

  def swap_transport() do
    Application.put_env(:farmbot_firmware, FarmbotFirmware,
      transport: UARTTransport,
      device: "/dev/ttyAMA0"
    )

    # Swap transport on FW module.
    # Close tranpsort if it is open currently.
    _ = FarmbotFirmware.close_transport()
    :ok = FarmbotFirmware.open_transport(UARTTransport, device: "/dev/ttyAMA0")
  end

  def stub do
    _ = FarmbotFirmware.close_transport()
    :ok = FarmbotFirmware.open_transport(StubTransport, [])
  end

  def update_param(param, value) do
    with :ok <- FarmbotFirmware.command({:parameter_write, [{param, value}]}),
         {:ok, {_, {:report_parameter_value, [{^param, ^value}]}}} <-
           FarmbotFirmware.request({:parameter_read, [param]}) do
      FarmbotCore.Logger.success(1, "Firmware parameter updated: #{param} #{value}")
      :ok
    else
      {:error, reason} ->
        FarmbotCore.Logger.error(
          1,
          "Error writing firmware parameter: #{param}: #{inspect(reason)}"
        )

      {:ok, {_, {:report_parameter_value, [{param, value}]}}} ->
        FarmbotCore.Logger.error(
          1,
          "Error writing firmware parameter #{param}: incorrect data reply: #{value}"
        )
    end
  end
end
