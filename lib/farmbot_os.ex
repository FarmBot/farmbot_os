defmodule FarmbotOS do
  @moduledoc false

  use Application

  @telemetry_config [
    access: :read_write,
    type: :set,
    file: '/tmp/farmbot_telemetry_new.dets'
  ]
  def start(_type, _args) do
    {:ok, :farmbot} = :dets.open_file(:farmbot, @telemetry_config)

    children = [
      FarmbotOS.Asset.Repo,
      FarmbotOS.EctoMigrator,
      FarmbotOS.BotState.Supervisor,
      FarmbotOS.Bootstrap,
      {FarmbotOS.Configurator.Supervisor, []},
      {FarmbotOS.Init.Supervisor, []},
      FarmbotOS.Leds,
      FarmbotOS.Celery.Scheduler,
      FarmbotOS.FirmwareEstopTimer,
      {FarmbotOS.Platform.Supervisor, []},
      FarmbotOS.Asset.Supervisor,
      FarmbotOS.Firmware.UARTObserver,
      {Task.Supervisor, name: FarmbotOS.Task.Supervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
