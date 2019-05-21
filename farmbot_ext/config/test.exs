use Mix.Config

config :farmbot_ext, FarmbotExt.API.Preloader, preloader_impl: MockPreloader
config :farmbot_ext, FarmbotExt.AMQP.ConnectionWorker, network_impl: MockConnectionWorker
config :farmbot_ext, FarmbotExt.AMQP.AutoSyncChannel, database_impl: MockQuery
