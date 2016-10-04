use Mix.Config
config :uart,
  baud: 115200

config :fb,
  ro_path: "/tmp"

config :json_rpc,
  transport: MqttHandler
