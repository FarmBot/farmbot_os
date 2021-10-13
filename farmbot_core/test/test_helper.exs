Application.ensure_all_started(:mimic)
tz = System.get_env("TZ") || Timex.local().time_zone

FarmbotCore.Asset.Device.changeset(FarmbotCore.Asset.device(), %{timezone: tz})
|> FarmbotCore.Asset.Repo.insert_or_update!()

[
  Circuits.UART,
  FarmbotCore.Celery,
  FarmbotCore.Celery.Compiler.Lua,
  FarmbotCore.Celery.Scheduler,
  FarmbotCore.Celery.SpecialValue,
  FarmbotCore.Celery.SysCalls,
  FarmbotCore.Celery.SysCalls.Stubs,
  FarmbotCore.Asset,
  FarmbotCore.Asset.Private,
  FarmbotCore.Asset.Repo,
  FarmbotCore.BotState,
  FarmbotCore.Firmware.Avrdude,
  FarmbotCore.Firmware.ConfigUploader,
  FarmbotCore.Firmware.Flash,
  FarmbotCore.Firmware.FlashUtils,
  FarmbotCore.Firmware.Resetter,
  FarmbotCore.Firmware.TxBuffer,
  FarmbotCore.Firmware.UARTCore,
  FarmbotCore.Firmware.UARTCoreSupport,
  FarmbotCore.Firmware.UARTDetector,
  FarmbotCore.FirmwareEstopTimer,
  FarmbotCore.LogExecutor,
  MuonTrap,
  NervesTime,
  Timex
]
|> Enum.map(&Mimic.copy/1)

ExUnit.configure(max_cases: 1)
ExUnit.start()
