use Mix.Config

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmEvent, checkup_time_ms: 10_000

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.RegimenInstance,
  checkup_time_ms: 10_000

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.Private.Alert,
  error_retry_time_ms: 10_000

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmwareInstallation,
  error_retry_time_ms: 30_000,
  install_dir: "/tmp/farmware"

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler,
  error_retry_time_ms: 30_000

config :farmbot_core, FarmbotCore.Leds, gpio_handler: FarmbotCore.Leds.StubHandler

config :farmbot_core, FarmbotCore.JSON, json_parser: FarmbotCore.JSON.JasonParser

# Customize non-Elixir parts of the firmware.  See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.
config :nerves, :firmware,
  rootfs_overlay: "rootfs_overlay",
  provisioning: :nerves_hub

config :farmbot_core, FarmbotCore.AssetMonitor, checkup_time_ms: 5_000

config :farmbot_core, FarmbotCore.EctoMigrator,
  expected_fw_versions: ["6.4.2.F", "6.4.2.R", "6.4.2.G"],
  default_firmware_io_logs: false,
  default_server: "https://my.farm.bot",
  default_ntp_server_1: "0.pool.ntp.org",
  default_ntp_server_2: "1.pool.ntp.org",
  default_dns_name: "my.farm.bot",
  default_currently_on_beta:
    String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta")

config :farmbot_celery_script, FarmbotCeleryScript.SysCalls, sys_calls: FarmbotOS.SysCalls

config :farmbot_core, FarmbotCore.BotState.FileSystem,
  root_dir: "/tmp/farmbot_state",
  sleep_time: 200

config :farmbot_core, FarmbotCore.FarmwareRuntime, runtime_dir: "/tmp/farmware_runtime"

config :ecto, json_library: FarmbotCore.JSON

config :farmbot_core,
  ecto_repos: [FarmbotCore.Config.Repo, FarmbotCore.Logger.Repo, FarmbotCore.Asset.Repo]

config :farmbot_ext, FarmbotExt.API.Preloader, preloader_impl: FarmbotExt.API.Preloader.HTTP

config :farmbot, FarmbotOS.FileSystem, data_path: "/tmp/farmbot"
config :farmbot, FarmbotOS.System, system_tasks: FarmbotOS.Platform.Host.SystemTasks

config :farmbot, FarmbotOS.Platform.Supervisor,
  platform_children: [
    FarmbotOS.Platform.Host.Configurator
  ]

import_config("lagger.exs")

config :logger,
  backends: [:console, RingLogger],
  handle_otp_reports: true,
  handle_sasl_reports: true

config :logger, :console, metadata: [:changeset, :module]

if Mix.target() == :host do
  if File.exists?("config/host/#{Mix.env()}.exs") do
    import_config("host/#{Mix.env()}.exs")
  end
else
  import_config("target/#{Mix.env()}.exs")

  if File.exists?("config/target/#{Mix.target()}.exs") do
    import_config("target/#{Mix.target()}.exs")
  end
end
