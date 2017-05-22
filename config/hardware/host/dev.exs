use Mix.Config

config :farmbot,
  config_file_name: System.get_env("CONFIG_FILE_NAME") || "default_config.json",
  configurator_port: System.get_env("CONFIGURATOR_PORT") || 5000,
  path: "/tmp/farmbot",
  tty: {:system, "ARDUINO_TTY"}

config :farmbot, :redis,
  server: System.get_env("REDIS_SERVER") || false,
  port: System.get_env("REDIS_SERVER_PORT") || 6379

# Transports
mqtt_transport = Farmbot.Transport.GenMqtt
# redis_transport = Farmbot.Transport.Redis

# frontend <-> bot transports.
config :farmbot, transports: [
  {mqtt_transport,  name: mqtt_transport},
  # {redis_transport, name: redis_transport}
]


config :wobserver,
  mode: :plug,
  remote_url_prefix: "/wobserver"
