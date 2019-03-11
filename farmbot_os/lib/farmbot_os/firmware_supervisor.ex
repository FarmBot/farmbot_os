defmodule FarmbotCore.FirmwareSupervisor do
  use Supervisor
  alias FarmbotCore.Asset.FbosConfig

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      FarmbotCore.FirmwareEstopTimer
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def firmware_children(%FbosConfig{} = fbos_config) do
    [
      {FarmbotFirmware,
       device: fbos_config.firmware_path,
       transport: FarmbotFirmware.UARTTransport,
       side_effects: FarmbotCore.FirmwareSideEffects}
    ]
  end
end
