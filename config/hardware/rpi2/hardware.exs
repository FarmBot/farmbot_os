use Mix.Config
config :farmbot,
  path: "/state",
  config_file_name: "default_config_rpi2.json",
  configurator_port: 80

config :farmbot, :redis,
  server: true,
  port: 6379
