use Mix.Config

if Mix.env() == :test do
  config :farmbot_firmware, :uart_adapter, FarmbotFirmware.UartTestAdapter
else
  IO.puts("!!!!!!!!! On CircleCI, Mix.env() == " <> Mix.env())
end
