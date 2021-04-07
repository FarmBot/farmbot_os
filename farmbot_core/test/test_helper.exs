Application.ensure_all_started(:mimic)
tz = System.get_env("TZ") || Timex.local().time_zone

FarmbotCore.Asset.Device.changeset(FarmbotCore.Asset.device(), %{timezone: tz})
|> FarmbotCore.Asset.Repo.insert_or_update!()

[
  FarmbotCore.Firmware.UARTSupport,
  FarmbotCeleryScript,
  FarmbotCeleryScript.SysCalls.Stubs,
  FarmbotCore.Asset,
  FarmbotCore.LogExecutor,
  Timex
]
|> Enum.map(&Mimic.copy/1)

ExUnit.configure(max_cases: 1)
ExUnit.start()
