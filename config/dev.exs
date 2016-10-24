use Mix.Config
config :uart,
  baud: 115200

config :fb,
  ro_path: "/tmp",
  bot_state_save_file: "/tmp/botstatus.txt"

config :json_rpc,
  transport: MqttHandler
