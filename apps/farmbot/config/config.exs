use Mix.Config

target = Mix.Project.config[:target]
env = Mix.env()
mqtt_transport = Farmbot.Transport.GenMqtt
redis_transport = Farmbot.Transport.Redis

config :logger, utc_log: true

# I force colors because they are important.
config :logger, :console, colors: [enabled: true, info: :cyan]

# Iex needs colors too.
config :iex, :colors, enabled: true

# send a message to these modules when we successfully log in.
config :farmbot, auth_callbacks: [mqtt_transport]

# frontend <-> bot transports.
config :farmbot, transports: [mqtt_transport, redis_transport]

# give the ability to start a redis server instance in dev mode.
config :farmbot, :redis,
  server: System.get_env("REDIS_SERVER") || false,
  port: System.get_env("REDIS_SERVER_PORT") || 6379

# This is usually in the `priv` dir of :tzdata, but our fs is read only.
config :tzdata, :data_dir, "/tmp"
config :tzdata, :autoupdate, :disabled

# Import configuration specific to out environment.
import_config "#{env}.exs"

# import config specific to our nerves_target
IO.puts "using #{target} - #{env} configuration."
import_config "hardware/#{target}/hardware.exs"
config :nerves, :firmware,
  rootfs_additions: "config/hardware/#{target}/rootfs-additions-#{env}"
