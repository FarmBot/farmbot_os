defmodule FarmbotOS do
  @moduledoc false

  use Application

  @telemetry_config [
    access: :read_write,
    type: :set,
    file: '/tmp/farmbot_telemetry.dets'
  ]
  def start(_type, _args) do
    {:ok, :farmbot_os} = :dets.open_file(:farmbot_os, @telemetry_config)

    children = [
      FarmbotCore.Asset.Repo,
      FarmbotOS.EctoMigrator,
      FarmbotExt.Bootstrap,
      {FarmbotOS.Configurator.Supervisor, []},
      {FarmbotOS.Init.Supervisor, []},
      {FarmbotOS.Platform.Supervisor, []},
      FarmbotCore.BotState.Supervisor,
      FarmbotCore.Celery.Scheduler,
      FarmbotCore.FirmwareEstopTimer,
      FarmbotCore.Leds,
      FarmbotCore.StorageSupervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
