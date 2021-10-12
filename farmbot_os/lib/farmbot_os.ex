defmodule FarmbotOS do
  @moduledoc false

  use Application

  def start(_type, _args) do
    farmbot_os = [
      FarmbotCore.Asset.Repo,
      {FarmbotOS.Configurator.Supervisor, []},
      {FarmbotOS.Init.Supervisor, []},
      {FarmbotOS.Platform.Supervisor, []}
    ]

    farmbot_core = [
      FarmbotCore.Leds,
      FarmbotCore.BotState.Supervisor,
      FarmbotCore.StorageSupervisor,
      FarmbotCore.FirmwareEstopTimer,
      FarmbotCore.Celery.Scheduler,
      FarmbotExt.Bootstrap
    ]

    children = farmbot_os ++ farmbot_core

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
