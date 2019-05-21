use Mix.Config
config :farmbot, FarmbotOS.FirmwareTTYDetector, expected_names: ["ttyUSB0", "ttyACM0"]

config :farmbot_firmware, FarmbotFirmware.UARTTransport,
  reset: FarmbotOS.Platform.Target.FirmwareReset.NULL

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.Leds.CircuitsHandler,
    FarmbotOS.FirmwareTTYDetector
  ]
