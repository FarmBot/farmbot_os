Application.ensure_all_started(:mimic)

[
  System,
  MuonTrap,
  File,
  FarmbotOS.UpdateSupport,
  FarmbotOS.SysCalls.ResourceUpdate,
  FarmbotOS.SysCalls.Movement,
  FarmbotOS.SysCalls.Farmware,
  FarmbotOS.SysCalls.ChangeOwnership.Support,
  FarmbotOS.SysCalls,
  FarmbotOS.Lua.Ext.Info,
  FarmbotOS.Lua.Ext.Firmware,
  FarmbotOS.Lua.Ext.DataManipulation,
  FarmbotOS.Configurator.FakeNetworkLayer,
  FarmbotOS.Configurator.DetsTelemetryLayer,
  FarmbotOS.Configurator.ConfigDataLayer,
  FarmbotExt.HTTP,
  FarmbotExt.Bootstrap.Authorization,
  FarmbotExt.API.Reconciler,
  FarmbotExt.API,
  FarmbotCore.LogExecutor,
  FarmbotCore.Firmware.Command,
  FarmbotCore.FarmwareRuntime,
  FarmbotCore.Config,
  FarmbotCore.BotState,
  FarmbotCore.Asset.Private,
  FarmbotCore.Asset.FirmwareConfig,
  FarmbotCore.Asset.FbosConfig,
  FarmbotCore.Asset.Device,
  FarmbotCore.Asset,
  FarmbotCeleryScript.SysCalls
]
|> Enum.map(&Mimic.copy/1)

ExUnit.configure(max_cases: 1)
ExUnit.start()
