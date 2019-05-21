defmodule FarmbotOS.Platform.Target.FirmwareReset.NULL do
  @moduledoc """
  Does nothing
  """
  @behaviour FarmbotFirmware.UARTTransport.Reset

  @impl FarmbotFirmware.UARTTransport.Reset
  def reset, do: :ok
end
