use Mix.Config
config :uart,
  baud: 115200

config :farmbot,
  state_path: "/tmp/state"

config :json_rpc,
  transport: Mqtt.Handler
