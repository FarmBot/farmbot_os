defmodule Farmbot.Core.FirmwareSupervisor do
  use Supervisor
  alias Farmbot.Asset

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      Farmbot.Core.FirmwareEstopTimer
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def firmware_children(%Asset.FbosConfig{} = fbos_config) do
    [
      {Farmbot.Firmware,
       device: fbos_config.firmware_path,
       transport: Farmbot.Firmware.UARTTransport,
       side_effects: Farmbot.Core.FirmwareSideEffects}
    ]
  end
end
