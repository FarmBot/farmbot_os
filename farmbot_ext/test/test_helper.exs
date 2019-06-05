# Mocking for FarmbotCore
Mox.defmock(FarmbotCore.Asset.Query, for: FarmbotCore.Asset.Query)
Mox.defmock(FarmbotCore.Asset.Command, for: FarmbotCore.Asset.Command)

# Mocking for FarmbotExt
Mox.defmock(FarmbotExt.API.Preloader, for: FarmbotExt.API.Preloader)
Mox.defmock(FarmbotExt.AMQP.ConnectionWorker, for: FarmbotExt.AMQP.ConnectionWorker)

Mox.defmock(FarmbotExt.AMQP.ConnectionWorker.Network,
  for: FarmbotExt.AMQP.ConnectionWorker.Network
)

ExUnit.start()
