use Mix.Config

config :farmbot_core,
       Elixir.FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey,
       ssh_handler: FarmbotCore.PublicKeyHandler.StubSSHHandler

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler

config :farmbot_core, FarmbotCore.Leds,
  gpio_handler: FarmbotCore.Leds.StubHandler

# Customize non-Elixir parts of the firmware.  See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.
config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :farmbot_core, FarmbotCore.EctoMigrator,
  default_firmware_io_logs: false,
  default_server: "https://my.farm.bot",
  default_ntp_server_1: "0.pool.ntp.org",
  default_ntp_server_2: "1.pool.ntp.org",
  default_dns_name: "my.farm.bot",
  default_currently_on_beta:
    String.contains?(
      to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')),
      "beta"
    )

config :farmbot_core, FarmbotCore.Celery.SysCalls, sys_calls: FarmbotOS.SysCalls

config :farmbot_core, FarmbotCore.BotState.FileSystem,
  root_dir: "/tmp/farmbot_state"

config :ecto, json_library: FarmbotCore.JSON

config :farmbot_core,
  ecto_repos: [
    FarmbotCore.Config.Repo,
    FarmbotCore.Logger.Repo,
    FarmbotCore.Asset.Repo
  ]

config :farmbot_ext, FarmbotExt.API.Preloader,
  preloader_impl: FarmbotExt.API.Preloader.HTTP

config :farmbot, FarmbotOS.FileSystem, data_path: "/tmp/farmbot"

config :farmbot, FarmbotOS.System,
  system_tasks: FarmbotOS.Platform.Host.SystemTasks

config :farmbot, FarmbotOS.Configurator,
  network_layer: FarmbotOS.Configurator.FakeNetworkLayer

config :farmbot, FarmbotOS.Platform.Supervisor,
  platform_children: [
    FarmbotOS.Platform.Host.Configurator
  ]

config :logger,
  handle_sasl_reports: false,
  handle_otp_reports: false

rollbar_token = System.get_env("ROLLBAR_TOKEN")

if rollbar_token && Mix.env() != :test do
  IO.puts("=== ROLLBAR IS ENABLED! ===")

  config :rollbax,
    access_token: rollbar_token,
    environment: "production",
    enable_crash_reports: true,
    custom: %{fbos_version: Mix.Project.config()[:version]}
else
  config :rollbax, enabled: false
end

if Mix.target() == :host do
  if File.exists?("config/host/#{Mix.env()}.exs") do
    import_config("host/#{Mix.env()}.exs")
  end
else
  import_config("target/#{Mix.env()}.exs")

  import_config("target/#{Mix.target()}.exs")
end

if Mix.env() == :test do
  config :farmbot_os,
         :reconciler,
         FarmbotExt.API.TestReconciler
end
