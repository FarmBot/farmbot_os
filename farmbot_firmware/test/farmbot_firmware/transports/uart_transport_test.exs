defmodule FarmbotFirmware.UARTTransportTest do
  use ExUnit.Case
  doctest FarmbotFirmware.UARTTransport

  test "FarmbotFirmware.UARTTransportTest.open/2" do
    FarmbotFirmware.UARTTransport.open(self(), "B", [])
    IO.puts("HEYOOO")
  end
end
