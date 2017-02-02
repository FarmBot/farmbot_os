use Mix.Config
config :farmbot_system,
  path: "/state",
  config_file_name: "default_config_rpi3.json"

config :farmbot_configurator,
  port: 80,
  streamer_port: 4040
