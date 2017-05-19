use Mix.Config
import_config "dev.exs"

# We hopefully don't need logger  ¯\_(ツ)_/¯
config :logger, :console, format: ""

config :farmbot,
  path: "/tmp/farmbot_test",
  config_file_name: "default_config.json",
  tty: "/dev/tnt1",
  logger: false


config :farmbot_simulator, :tty, "tnt0"
