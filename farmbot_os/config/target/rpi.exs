use Mix.Config

config :farmbot_core, FarmbotCore.FirmwareTTYDetector, expected_names: ["ttyUSB0", "ttyAMA0"]

config :farmbot_firmware, FarmbotFirmware.UARTTransport,
  reset: FarmbotOS.Platform.Target.FirmwareReset.GPIO

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.FirmwareReset.GPIO
  ]
