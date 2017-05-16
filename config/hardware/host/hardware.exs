use Mix.Config
config :farmbot,
  path: "/tmp/farmbot",
  config_file_name: System.get_env("CONFIG_FILE_NAME") || "default_config.json",
  configurator_port: System.get_env("CONFIGURATOR_PORT") || 5000
