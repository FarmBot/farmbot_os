defmodule FarmbotFirmware.UARTTransport.Reset do
  @moduledoc """
  Behaviour to reset the UART connection into 
  bootloader mode for firmware upgrades.
  """

  @callback reset :: :ok | {:error, Stirng.t()}
end
