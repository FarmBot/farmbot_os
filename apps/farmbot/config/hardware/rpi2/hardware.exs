use Mix.Config
config :farmbot_system,
  path: "/state",
  config_file_name: "default_config_rpi2.json"

config :farmbot,
  configurator_port: 80,
  streamer_port: 4040
