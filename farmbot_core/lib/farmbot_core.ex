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

    children = [
      FarmbotCore.EctoMigrator,
      FarmbotCore.BotState.Supervisor,
      FarmbotCore.StorageSupervisor,
      FarmbotCore.FirmwareEstopTimer,
      # Also error handling for a transport not starting ?
      {FarmbotFirmware, transport: FarmbotFirmware.StubTransport, side_effects: FarmbotCore.FirmwareSideEffects},
      FarmbotCeleryScript.Scheduler
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
