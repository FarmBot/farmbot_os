defmodule Farmbot.Firmware.UartHandler.AutoDetector do
  @moduledoc """
  Init module for configuring a UART handler. Here's what it does:

  * Enumerates Serial devices
  * Scrubs devices that should be ignored.
  * If there is *ONE* device:
    * Configures Farmbot.Behaviour.FirmwareHandler -> UartHandler
    * Configures the device to be used.
  * If there are zero or more than one device:
    * Configures Farmbot.Behaviour.FirmwareHandler -> StubHandler
  """

  alias Nerves.UART
  alias Farmbot.Firmware.{UartHandler, StubHandler, Utils}
  import Utils
  use Farmbot.Logger

  #TODO(Connor) - Maybe make this configurable?
  case Farmbot.Project.target() do
    :rpi3 ->
      @ignore_devs ["ttyAMA0", "ttyS0", "ttyS3"]
    :rpi ->
      @ignore_devs ["ttyS0", "ttyS3"]
    :rpi0 ->
      @ignore_devs ["ttyS0", "ttyS3"]
    :host ->
      @ignore_devs ["ttyS0"]
  end

  @doc "Autodetect relevent UART Devs."
  def auto_detect do
    UART.enumerate() |> Map.keys() |> Kernel.--(@ignore_devs)
  end

  @doc false
  def start_link(_, _) do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    update_env()
    :ignore
  end

  def update_env do
    case auto_detect() do
      [dev] ->
        dev = "/dev/#{dev}"
        Logger.success 3, "detected target UART: #{dev}"
        replace_firmware_handler(UartHandler)
        Application.put_env(:farmbot, :uart_handler, tty: dev)
        dev
      _ ->
        Logger.error 1, "Could not detect a UART device."
        replace_firmware_handler(StubHandler)
        :error
    end
  end
end
