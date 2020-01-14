use Mix.Config

if Mix.env() == :test do
  config :farmbot_firmware, :uart_adapter, FarmbotFirmware.UartTestAdapter
end
