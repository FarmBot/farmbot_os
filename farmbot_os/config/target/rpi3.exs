use Mix.Config

config :farmbot_firmware, FarmbotFirmware, reset: FarmbotFirmware.NullReset

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.RTCWorker
  ]
