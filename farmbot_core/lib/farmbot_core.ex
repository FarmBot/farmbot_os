defmodule FarmbotCore do
  @moduledoc """
  Core Farmbot Services.
  This includes
    * Core global state management
    * Data storage management
    * Firmware management
    * RPC and IPC management

  """
  use Application

  @doc false
  def start(_, args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  def init([]) do
    Supervisor.init(children(), [strategy: :one_for_one])
  end

  def children do
    default = [
      FarmbotCore.Leds,
      FarmbotCore.EctoMigrator,
      FarmbotCore.BotState.Supervisor,
      FarmbotCore.StorageSupervisor,
      FarmbotCore.FirmwareEstopTimer,
      FarmbotCore.Celery.Scheduler,
      FarmbotExt.Bootstrap
    ]
    config = (Application.get_env(:farmbot_core, __MODULE__) || [])
    Keyword.get(config, :children, default)
  end
end
