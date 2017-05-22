use Mix.Config
config :farmbot,
  config_file_name: "default_config.json",
  configurator_port: 5001,
  path: "/tmp/farmbot_test",
  config_file_name: "default_config.json",
  tty: "/dev/tnt1",
  logger: false

config :farmbot_simulator, :tty, "tnt0"

config :farmbot, :redis,
  server: false

config :farmbot, transports: []

# We hopefully don't need logger  ¯\_(ツ)_/¯
config :logger, :console, format: ""
