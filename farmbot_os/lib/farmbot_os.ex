defmodule FarmbotOS do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      FarmbotCore.Asset.Repo,
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
