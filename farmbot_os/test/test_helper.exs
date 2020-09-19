Application.ensure_all_started(:mimic)

[
  FarmbotCore.Asset.Device,
  FarmbotCore.Asset.FbosConfig,
  FarmbotCore.Asset.FirmwareConfig,
  FarmbotCore.Asset,
  FarmbotCore.BotState,
  FarmbotCore.Config,
  FarmbotCore.FarmwareRuntime,
  FarmbotCore.LogExecutor,
  FarmbotExt.API.Reconciler,
  FarmbotExt.API,
  FarmbotFirmware,
  FarmbotOS.Configurator.ConfigDataLayer,
  FarmbotOS.Configurator.DetsTelemetryLayer,
  FarmbotOS.Configurator.FakeNetworkLayer,
  FarmbotOS.SysCalls.Movement,
  FarmbotOS.SysCalls,
  File,
  MuonTrap,
  FarmbotCeleryScript.SysCalls,
  System
]
|> Enum.map(&Mimic.copy/1)

ExUnit.start()
