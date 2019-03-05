defmodule FarmbotCore do
  @moduledoc """
  Core Farmbot Services.
  This includes Logging, Configuration, Asset management and Firmware.
  """
  use Application

  @doc false
  def start(_, args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  def init([]) do

    children = [
      FarmbotCore.EctoMigrator,
      # TODO(Connor) - Put these in their own supervisor
      FarmbotCore.BotState,
      FarmbotCore.BotState.FileSystem,
      FarmbotCore.Logger.Supervisor,
      FarmbotCore.Config.Supervisor,
      FarmbotCore.Asset.Supervisor,
      FarmbotCore.FirmwareSupervisor,
      FarmbotCeleryScript.Scheduler,
    ]
    Supervisor.init(children, [strategy: :one_for_all])
  end
end
