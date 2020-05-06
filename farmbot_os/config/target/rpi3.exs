use Mix.Config

config :farmbot_firmware, FarmbotFirmware, reset: FarmbotCore.FirmwareResetter

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.RTCWorker
  ]
