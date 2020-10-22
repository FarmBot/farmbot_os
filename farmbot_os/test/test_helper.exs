Application.ensure_all_started(:mimic)

[
  FarmbotOS.SysCalls.Movement,
  MuonTrap,
  FarmbotOS.SysCalls,
  FarmbotCore.Asset,
  FarmbotOS.Configurator.ConfigDataLayer,
  FarmbotExt.Bootstrap.Authorization,
  File,
  FarmbotOS.Configurator.DetsTelemetryLayer,
  FarmbotCore.Asset.FirmwareConfig,
  FarmbotOS.UpdateSupport,
  FarmbotCore.Asset.FbosConfig,
  FarmbotExt.API.Reconciler,
  FarmbotCore.LogExecutor,
  FarmbotCore.Config,
  FarmbotOS.Configurator.FakeNetworkLayer,
  FarmbotCore.FarmwareRuntime,
  FarmbotCeleryScript.SysCalls,
  FarmbotExt.API,
  FarmbotCore.BotState,
  FarmbotOS.SysCalls.ChangeOwnership.Support,
  FarmbotFirmware,
  System,
  FarmbotCore.Asset.Device
]
|> Enum.map(&Mimic.copy/1)

ExUnit.configure(max_cases: 1)
ExUnit.start()
