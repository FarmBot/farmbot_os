use Mix.Config
is_test? = Mix.env() == :test
rollbar_token = System.get_env("ROLLBAR_TOKEN")
config :mime, :types, %{}
config :exqlite, :json_library, FarmbotOS.JSON
config :farmbot, ecto_repos: [FarmbotOS.Asset.Repo]
config :logger, backends: [:console]
config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"
config :tesla, adapter: Tesla.Adapter.Hackney

%{
  Elixir.FarmbotOS.AssetWorker.FarmbotOS.Asset.PublicKey => [
    ssh_handler: FarmbotOS.PublicKeyHandler.StubSSHHandler
  ],
  FarmbotOS.Asset.Repo => [
    database: "database.#{Mix.env()}.db",
    log: false
  ],
  FarmbotOS.AssetWorker.FarmbotOS.Asset.PinBinding => [
    gpio_handler: FarmbotOS.PinBindingWorker.StubGPIOHandler
  ],
  FarmbotOS.BotState.FileSystem => [root_dir: "/tmp/farmbot_state"],
  FarmbotOS.Celery.SysCallGlue => [sys_calls: FarmbotOS.SysCalls],
  FarmbotOS.Core.CeleryScript.RunTimeWrapper => [
    celery_script_io_layer: FarmbotOS.Core.CeleryScript.StubIOLayer
  ],
  FarmbotOS.JSON => [json_parser: FarmbotOS.JSON.JasonParser],
  FarmbotOS.Leds => [gpio_handler: FarmbotOS.Leds.StubHandler],
  FarmbotOS.Time => [disable_timeouts: is_test?],
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
