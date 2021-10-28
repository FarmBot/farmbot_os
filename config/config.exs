use Mix.Config
is_test? = Mix.env() == :test
rollbar_token = System.get_env("ROLLBAR_TOKEN")

config :exqlite, :json_library, FarmbotCore.JSON
config :farmbot, ecto_repos: [FarmbotCore.Asset.Repo]
config :logger, backends: [:console]
config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"
config :tesla, adapter: Tesla.Adapter.Hackney

%{
  Elixir.FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey => [
    ssh_handler: FarmbotCore.PublicKeyHandler.StubSSHHandler
  ],
  FarmbotCore.Asset.Repo => [
    database: "database.#{Mix.env()}.db",
    log: false
  ],
  FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding => [
    gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler
  ],
  FarmbotCore.BotState.FileSystem => [root_dir: "/tmp/farmbot_state"],
  FarmbotCore.Celery.SysCallGlue => [sys_calls: FarmbotOS.SysCalls],
  FarmbotCore.Core.CeleryScript.RunTimeWrapper => [
    celery_script_io_layer: FarmbotCore.Core.CeleryScript.StubIOLayer
  ],
  FarmbotCore.JSON => [json_parser: FarmbotCore.JSON.JasonParser],
  FarmbotCore.Leds => [gpio_handler: FarmbotCore.Leds.StubHandler],
  FarmbotExt.API.Preloader => [preloader_impl: FarmbotExt.API.Preloader.HTTP],
  FarmbotExt.Time => [disable_timeouts: is_test?],
  FarmbotOS.Configurator => [
    network_layer: FarmbotOS.Configurator.FakeNetworkLayer
  ],
  FarmbotOS.FileSystem => [data_path: "/tmp/farmbot"],
  FarmbotOS.Platform.Supervisor => [
    platform_children: [FarmbotOS.Platform.Host.Configurator]
  ],
  FarmbotOS.System => [system_tasks: FarmbotOS.Platform.Host.SystemTasks]
}
|> Enum.map(fn {m, c} -> config :farmbot, m, c end)

if rollbar_token && !is_test? do
  config :rollbax,
    access_token: rollbar_token,
    environment: "production",
    enable_crash_reports: true,
    custom: %{
      fbos_version: Mix.Project.config()[:version],
      fbos_target: Mix.target()
    }
else
  config :rollbax, enabled: false
end

if Mix.target() == :host do
  ok? = File.exists?("config/#{Mix.env()}.exs")
  ok? && import_config("#{Mix.env()}.exs")
else
  import_config("target.exs")
end
