use Mix.Config

config :farmbot_core, FarmbotCore.FirmwareTTYDetector, expected_names: ["ttyUSB0", "ttyACM0"]

config :farmbot_firmware, FarmbotFirmware.UARTTransport,
  reset: FarmbotOS.Platform.Target.FirmwareReset.NULL

config :farmbot, FarmbotOS.Init.Supervisor, init_children: []
