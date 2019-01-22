use Mix.Config

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmEvent, checkup_time_ms: 10_000
config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.PersistentRegimen, checkup_time_ms: 10_000

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmwareInstallation,
  error_retry_time_ms: 30_000,
  install_dir: "/tmp/farmware"

config :farmbot_core, Elixir.Farmbot.AssetWorker.Farmbot.Asset.PinBinding,
  gpio_handler: Farmbot.PinBindingWorker.StubGPIOHandler,
  error_retry_time_ms: 30_000

config :farmbot_core, Farmbot.Leds, gpio_handler: Farmbot.Leds.StubHandler

config :farmbot_core, Farmbot.JSON, json_parser: Farmbot.JSON.JasonParser

# Customize non-Elixir parts of the firmware.  See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.
config :nerves, :firmware,
  rootfs_overlay: "rootfs_overlay",
  provisioning: :nerves_hub

config :farmbot_core, Farmbot.AssetMonitor, checkup_time_ms: 30_000

config :farmbot_core, Farmbot.EctoMigrator,
  default_firmware_io_logs: false,
  default_server: "https://my.farm.bot",
  default_currently_on_beta:
    String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta")

config :farmbot_core, Farmbot.Core.CeleryScript.RunTimeWrapper,
  celery_script_io_layer: Farmbot.OS.IOLayer

config :farmbot_core, Farmbot.BotState.FileSystem,
  root_dir: "/tmp/farmbot_state",
  sleep_time: 200

config :ecto, json_library: Farmbot.JSON

config :farmbot_core,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo]

config :farmbot, Farmbot.OS.FileSystem, data_path: "/tmp/farmbot"
config :farmbot, Farmbot.System, system_tasks: Farmbot.Host.SystemTasks

config :farmbot, Farmbot.Platform.Supervisor,
  platform_children: [
    Farmbot.Host.Configurator
  ]

import_config("lagger.exs")
config :logger, backends: [:console]
config :logger, :console, metadata: [:changeset, :module]

if Mix.Project.config()[:target] == "host" do
  if File.exists?("config/host/#{Mix.env()}.exs") do
    import_config("host/#{Mix.env()}.exs")
  end
else
  import_config("target/#{Mix.env()}.exs")

  if File.exists?("config/target/#{Mix.Project.config()[:target]}.exs") do
    import_config("target/#{Mix.Project.config()[:target]}.exs")
  end
end
