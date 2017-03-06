use Mix.Config
config :farmbot,
  path: "/tmp",
  config_file_name: System.get_env("CONFIG_FILE_NAME") || "default_config.json"
