use Mix.Config
import_config "dev.exs"

config :json_rpc,
  transport: FakeMqtt
