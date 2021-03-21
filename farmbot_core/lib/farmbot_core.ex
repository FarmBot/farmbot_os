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
    allow = [
      FarmbotCore.EctoMigrator,
      FarmbotCore.Leds,
      FarmbotCore.StorageSupervisor,
      FarmbotCeleryScript.Scheduler,
      FarmbotCore.BotState.Supervisor,
      FarmbotCore.FirmwareTTYDetector,
      FarmbotCore.FirmwareEstopTimer,
      FarmbotCore.FirmwareOpenTask,
      {FarmbotFirmware,
    transport: FarmbotFirmware.StubTransport,
    side_effects: FarmbotCore.FirmwareSideEffects,
    reset: FarmbotCore.FirmwareResetter}
    ]
    config = (Application.get_env(:farmbot_ext, __MODULE__) || [])
    Keyword.get(config, :children, allow)
  end
end
