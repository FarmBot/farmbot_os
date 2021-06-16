Application.ensure_all_started(:mimic)
tz = System.get_env("TZ") || Timex.local().time_zone

FarmbotCore.Asset.Device.changeset(FarmbotCore.Asset.device(), %{timezone: tz})
|> FarmbotCore.Asset.Repo.insert_or_update!()

[
  Timex,
  MuonTrap,
  FarmbotCore.LogExecutor,
  FarmbotCore.FirmwareEstopTimer,
  FarmbotCore.Firmware.UARTDetector,
  FarmbotCore.Firmware.UARTCoreSupport,
  FarmbotCore.Firmware.UARTCore,
  FarmbotCore.Firmware.TxBuffer,
  FarmbotCore.Firmware.Resetter,
  FarmbotCore.Firmware.FlashUtils,
  FarmbotCore.Firmware.Flash,
  FarmbotCore.Firmware.ConfigUploader,
  FarmbotCore.Firmware.Avrdude,
  FarmbotCore.BotState,
  FarmbotCore.Asset.Private,
  FarmbotCore.Asset,
  FarmbotCeleryScript.SysCalls.Stubs,
  FarmbotCeleryScript,
  Circuits.UART
]
|> Enum.map(&Mimic.copy/1)

ExUnit.configure(max_cases: 1)
ExUnit.start()
