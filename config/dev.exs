use Mix.Config
config :uart,
  baud: 115200

config :fb,
  state_path: "/tmp/state"

config :json_rpc,
  transport: Mqtt.Handler
