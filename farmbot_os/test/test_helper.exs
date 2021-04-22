Application.ensure_all_started(:mimic)

[
  FarmbotCeleryScript.SysCalls,
  FarmbotCore.Asset,
  FarmbotCore.Asset.Device,
  FarmbotCore.Asset.FbosConfig,
  FarmbotCore.Asset.FirmwareConfig,
  FarmbotCore.Asset.Private,
  FarmbotCore.BotState,
  FarmbotCore.Config,
  FarmbotCore.FarmwareRuntime,
  FarmbotCore.LogExecutor,
  FarmbotExt.API,
  FarmbotExt.API.Reconciler,
  FarmbotExt.Bootstrap.Authorization,
  FarmbotExt.HTTP,
  FarmbotCore.Firmware.Command,
  FarmbotOS.Configurator.ConfigDataLayer,
  FarmbotOS.Configurator.DetsTelemetryLayer,
  FarmbotOS.Configurator.FakeNetworkLayer,
  FarmbotOS.Lua.Ext.DataManipulation,
  FarmbotOS.Lua.Ext.Firmware,
  FarmbotOS.Lua.Ext.Info,
  FarmbotOS.SysCalls,
  FarmbotOS.SysCalls.ChangeOwnership.Support,
  FarmbotOS.SysCalls.Farmware,
  FarmbotOS.SysCalls.Movement,
  FarmbotOS.SysCalls.ResourceUpdate,
  FarmbotOS.UpdateSupport,
  File,
  MuonTrap,
  System
]
|> Enum.map(&Mimic.copy/1)

ExUnit.configure(max_cases: 1)
ExUnit.start()
