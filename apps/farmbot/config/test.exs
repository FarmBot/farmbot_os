use Mix.Config
import_config "dev.exs"

# We hopefully don't need logger  ¯\_(ツ)_/¯
config :logger, :console,
  format: ""

config :farmbot_filesystem,
  path: "/tmp",
  config_file_name: "default_config.json"
