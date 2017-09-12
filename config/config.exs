use Mix.Config

# Mix configs.
target = Mix.Project.config[:target]
env    = Mix.env()

config :logger, utc_log: true

config :ssl, protocol_version: :"tlsv1.2"

# I force colors because they are important.
config :logger, :console,
  colors: [enabled: true, info: :cyan],
  metadata: [:module],
  format: "$time $metadata[$level] $levelpad$message\n"

# Iex needs colors too.
config :iex, :colors, enabled: true

# This is usually in the `priv` dir of :tzdata, but our fs is read only.
config :tzdata, :data_dir, "/tmp"
config :tzdata, :autoupdate, :disabled

# Path for the `fs` module to watch.
config :fs, path: "/tmp/images"

# Configure your our system.
# Default implementation needs no special stuff.
# See Farmbot.System.Supervisor and Farmbot.System.Init for details.
config :farmbot, :init, []

# Transports.
config :farmbot, :transport, []


# Configure Farmbot Behaviours.
config :farmbot, :behaviour, [
  authorization: Farmbot.Bootstrap.Authorization,
]

case target do
  "host" -> import_config("host/#{env}.exs")
  _ ->
    if File.exists?("config/#{target}/#{env}.exs") do
      import_config("#{target}/#{env}.exs")
    else
      import_config("target/#{env}.exs")
    end
end
