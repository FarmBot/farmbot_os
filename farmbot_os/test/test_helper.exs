Application.ensure_all_started(:mimic)

[
  FarmbotCeleryScript.SysCalls,
  FarmbotCore.Asset,
  FarmbotCore.Asset.Device,
  FarmbotCore.Asset.FbosConfig,
  FarmbotCore.Asset.FirmwareConfig,
  FarmbotCore.BotState,
  FarmbotCore.Config,
  FarmbotCore.FarmwareRuntime,
  FarmbotCore.LogExecutor,
  FarmbotExt.API,
  FarmbotExt.API.Reconciler,
  FarmbotFirmware,
  FarmbotOS.Configurator.ConfigDataLayer,
  FarmbotOS.Configurator.DetsTelemetryLayer,
  FarmbotOS.Configurator.FakeNetworkLayer,
  FarmbotOS.SysCalls,
  FarmbotOS.SysCalls.Movement,
  FarmbotOS.UpdateSupport,
  File,
  MuonTrap,
  System
]
|> Enum.map(&Mimic.copy/1)

ExUnit.start()
