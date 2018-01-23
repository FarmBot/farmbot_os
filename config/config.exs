use Mix.Config

# Mix configs.
target = Mix.Project.config()[:target]
env = Mix.env()

config :logger, [
  utc_log: true,
  # handle_otp_reports: true,
  # handle_sasl_reports: true,
  # backends: []
]

config :farmbot, :logger, [
  # backends: [Elixir.Logger.Backends.Farmbot]
]

config :elixir, ansi_enabled: true
config :iex, :colors, enabled: true

config :ssl, protocol_version: :"tlsv1.2"

config :farmbot, farm_event_debug_log: false

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
  http_adapter: Farmbot.HTTP.HTTPoisonAdapter,
  gpio_handler: Farmbot.System.GPIO.StubHandler

config :farmbot, :farmware,
  first_part_farmware_manifest_url: "https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/manifest.json"

config :farmbot, expected_fw_versions: ["6.0.0.F", "6.0.0.R"]

case target do
  "host" ->
    import_config("host/#{env}.exs")

  _ ->
    import_config("target/#{env}.exs")
    if File.exists?("config/target/#{target}.exs") do
      import_config("target/#{target}.exs")
    end

    rootfs_overlay_dir = "config/target/rootfs_overlay_#{Mix.Project.config[:target]}"

    if File.exists?(rootfs_overlay_dir) do
      config :nerves, :firmware, rootfs_overlay: rootfs_overlay_dir
    end
end
