use Mix.Config

# Mix configs.
target = Mix.Project.config[:target]
env = Mix.env()

config :logger, utc_log: true

config :ssl, protocol_version: :"tlsv1.2"

# I force colors because they are important.
config :logger, :console,
  colors: [enabled: true, info: :cyan],
  metadata: [:module],
  format: "$time $metadata[$level] $levelpad$message\n"

# Iex needs colors too.
config :iex, :colors, enabled: true

# bot <-> firmware transports.
config :farmbot, expected_fw_version: "4.0.2"

# Rollbar
config :farmbot, rollbar_access_token: "dcd79b191ab84aa3b28259cbb80e2060"

# This is usually in the `priv` dir of :tzdata, but our fs is read only.
config :tzdata, :data_dir, "/tmp"
config :tzdata, :autoupdate, :disabled

# Path for the `fs` module to watch.
config :fs, path: "/tmp/images"

# import config specific to our nerves_target
IO.puts "using #{target} - #{env} configuration."
import_config "hardware/#{target}/#{env}.exs"
config :nerves, :firmware,
  rootfs_additions: "config/hardware/#{target}/rootfs-additions-#{env}"
