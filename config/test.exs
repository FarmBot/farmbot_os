use Mix.Config
import_config "dev.exs"

config :json_rpc,
  transport: FakeMqtt

# We hopefully don't need logger  ¯\_(ツ)_/¯
config :logger, :console,
  format: ""
