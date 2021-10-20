defmodule FarmbotOS do
  @moduledoc false

  use Application

  @telemetry_config [
    access: :read_write,
    type: :set,
    file: '/tmp/farmbot_telemetry.dets'
  ]
  def start(_type, _args) do
    {:ok, :farmbot} = :dets.open_file(:farmbot, @telemetry_config)

    children = [
      FarmbotCore.Asset.Repo,
      FarmbotOS.EctoMigrator,
      FarmbotCore.BotState.Supervisor,
      FarmbotExt.Bootstrap,
      {FarmbotOS.Configurator.Supervisor, []},
      {FarmbotOS.Init.Supervisor, []},
      FarmbotCore.Leds,
      FarmbotCore.Celery.Scheduler,
      FarmbotCore.FirmwareEstopTimer,
      FarmbotCore.StorageSupervisor,
      {FarmbotOS.Platform.Supervisor, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
