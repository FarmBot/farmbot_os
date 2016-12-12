use Mix.Config
import_config "dev.exs"

# We hopefully don't need logger  ¯\_(ツ)_/¯
config :logger, :console,
  format: ""

config :farmbot, state_path: "/tmp/please_dont_exist"
