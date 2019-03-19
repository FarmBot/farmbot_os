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
      # TODO:
      #   * Find device
      #   * Detect firmware version
      #   * Raise enigma as needed
      #   * Needs to be dynamically started/supervised
      {FarmbotFirmware, transport: FarmbotFirmware.StubTransport},
      FarmbotCore.EnigmaHandler,
      FarmbotCeleryScript.Scheduler
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
