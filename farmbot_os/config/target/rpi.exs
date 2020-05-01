use Mix.Config

config :farmbot_firmware, FarmbotFirmware,
  reset: FarmbotOS.Platform.Target.FirmwareReset.GPIO

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.RTCWorker
  ]

# :farmbot_firmware, FarmbotFirmware changes too much.
# Needed one that would stay stable, so I duplicated it here:
config :farmbot, FarmbotOS.SysCalls.FlashFirmware, gpio: Circuits.GPIO
