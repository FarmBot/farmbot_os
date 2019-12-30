use Mix.Config

config :farmbot_core, FarmbotCore.FirmwareTTYDetector, expected_names: ["ttyUSB0", "ttyACM0"]

config :farmbot_firmware, FarmbotFirmware, reset: FarmbotFirmware.NullReset

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.RTCWorker
  ]
