defmodule FarmbotOS.Platform.Target.FirmwareReset.NULL do
  @moduledoc """
  Does nothing in reference to resetting the firmware port
  """
  @behaviour FarmbotFirmware.UARTTransport.Reset

  @impl FarmbotFirmware.UARTTransport.Reset
  def reset, do: :ok
end
