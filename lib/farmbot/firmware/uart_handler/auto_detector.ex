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
  alias Farmbot.Firmware.{UartHandler, StubHandler}
  use Farmbot.Logger

  #TODO(Connor) - Maybe make this configurable?
  @ignore_devs ["ttyAMA0", "ttyS0"]

  @doc "Autodetect relevent UART Devs."
  def auto_detect do
    UART.enumerate() |> Map.keys() |> Kernel.--(@ignore_devs)
  end

  @doc false
  def start_link(_, _) do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    case auto_detect() do
      [dev] ->
        Logger.success 3, "detected target UART: #{dev}"
        update_fw_handler UartHandler
        Application.put_env(:farmbot, :uart_handler, tty: "/dev/ttyACM0")
      _ ->
        Logger.error 1, "Could not detect a UART device."
        update_fw_handler StubHandler
    end
    :ignore
  end

  defp update_fw_handler(fw_handler) do
    old = Application.get_all_env(:farmbot)[:behaviour]
    new = Keyword.put(old, :firmware_handler, fw_handler)
    Application.put_env(:farmbot, :behaviour, new)
  end

end
