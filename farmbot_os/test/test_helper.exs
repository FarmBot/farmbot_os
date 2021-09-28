Application.ensure_all_started(:mimic)

[
  FarmbotCore.Celery.SpecialValue,
  FarmbotCore.Celery.SysCalls,
  FarmbotCore.Asset,
  FarmbotCore.Asset.Device,
  FarmbotCore.Asset.FbosConfig,
  FarmbotCore.Asset.FirmwareConfig,
  FarmbotCore.Asset.Private,
  FarmbotCore.BotState,
  FarmbotCore.Config,
  FarmbotCore.FarmwareRuntime,
  FarmbotCore.Firmware.Command,
  FarmbotCore.Leds,
  FarmbotCore.LogExecutor,
  FarmbotExt.API,
  FarmbotExt.API.Reconciler,
  FarmbotExt.Bootstrap.Authorization,
  FarmbotTelemetry.HTTP,
  FarmbotOS.Configurator.ConfigDataLayer,
  FarmbotOS.Configurator.DetsTelemetryLayer,
  FarmbotOS.Configurator.FakeNetworkLayer,
  FarmbotOS.Lua.DataManipulation,
  FarmbotOS.Lua.Firmware,
  FarmbotOS.Lua.Info,
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
