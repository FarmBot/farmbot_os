use Mix.Config

config :farmbot_core, FarmbotCore.FirmwareTTYDetector,
  expected_names: ["ttyUSB0", "ttyAMA0"]

config :farmbot_core, FarmbotCore.FirmwareOpenTask, attempt_threshold: 50

config :farmbot_firmware, FarmbotFirmware,
  reset: FarmbotOS.Platform.Target.FirmwareReset.GPIO

# :farmbot_firmware, FarmbotFirmware changes too much.
# Needed one that would stay stable, so I duplicated it here:
config :farmbot, FarmbotOS.SysCalls.FlashFirmware, gpio: Circuits.GPIO

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.RTCWorker
  ]
