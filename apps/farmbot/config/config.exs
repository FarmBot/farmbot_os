use Mix.Config

target = Mix.Project.config[:target]
env = Mix.env()
mqtt_transport = Farmbot.Transport.GenMqtt

config :logger, utc_log: true

# I force colors because they are important.
config :logger, :console, colors: [enabled: true]


# Iex needs colors too.
config :iex, :colors, enabled: true

# send a message to these modules when we successfully log in.
config :farmbot_auth, callbacks: [mqtt_transport]

# frontend <-> bot transports.
config :farmbot, transports: [mqtt_transport]

config :nerves, :firmware,
  rootfs_additions: "config/hardware/#{target}/rootfs-additions-#{env}"

# This is usually in the `priv` dir of :tzdata, but our fs is read only.
config :tzdata, :data_dir, "/tmp"
config :tzdata, :autoupdate, :disabled

# Import configuration specific to out environment.
import_config "#{env}.exs"

# import config specific to our nerves_target
IO.puts "using #{target} - #{env} configuration."
import_config "hardware/#{target}/hardware.exs"
