use Mix.Config

config :farmbot, FarmbotOS.FirmwareTTYDetector, expected_names: ["ttyUSB0", "ttyAMA0"]

config :farmbot_firmware, FarmbotFirmware.UARTTransport,
  reset: FarmbotOS.Platform.Target.FirmwareReset

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.FirmwareReset,
    FarmbotOS.Platform.Target.Leds.CircuitsHandler,
    FarmbotOS.FirmwareTTYDetector
  ]
