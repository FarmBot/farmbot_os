use Mix.Config

# Mix configs.
target = Mix.Project.config()[:target]
env = Mix.env()

config :logger,
  utc_log: true,
  # handle_otp_reports: true,
  # handle_sasl_reports: true,
  backends: []

config :elixir, ansi_enabled: true
config :iex, :colors, enabled: true

config :ssl, protocol_version: :"tlsv1.2"

# This is usually in the `priv` dir of :tzdata, but our fs is read only.
config :tzdata, :data_dir, "/tmp"
config :tzdata, :autoupdate, :disabled

# Path for the `fs` module to watch.
# config :fs, path: "/tmp/images"

# Configure your our system.
# Default implementation needs no special stuff.
# See Farmbot.System.Supervisor and Farmbot.System.Init for details.
config :farmbot, :init, []

# Transports.
# See Farmbot.BotState.Transport for details.
config :farmbot, :transport, []

config :wobserver,
  discovery: :none,
  mode: :plug,
  remote_url_prefix: "/wobserver"

# Configure Farmbot Behaviours.
config :farmbot, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization,
  firmware_handler: Farmbot.Firmware.StubHandler,
  http_adapter: Farmbot.HTTP.HTTPoisonAdapter

config :farmbot, :farmware,
  first_part_farmware_manifest_url: "https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/manifest.json"

case target do
  "host" ->
    import_config("host/#{env}.exs")

  _ ->
    if File.exists?("config/#{target}/#{env}.exs") do
      import_config("#{target}/#{env}.exs")
    else
      import_config("target/#{env}.exs")
    end

    rootfs_overlay_dir = "config/target/rootfs_overlay_#{Mix.Project.config()[:target]}"

    if File.exists?(rootfs_overlay_dir) do
      config :nerves, :firmware, rootfs_overlay: rootfs_overlay_dir
    end
end
