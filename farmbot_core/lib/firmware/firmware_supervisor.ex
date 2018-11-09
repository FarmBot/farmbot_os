defmodule Farmbot.Core.FirmwareSupervisor do
  use Supervisor
  alias Farmbot.Asset

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def re_initialize do
    _ = Supervisor.terminate_child(Farmbot.Core, __MODULE__)
    Supervisor.restart_child(Farmbot.Core, __MODULE__)
  end

  def init([]) do
    fbos_config = Asset.fbos_config()

    firmware_children =
      if fbos_config.firmware_hardware && fbos_config.firmware_path do
        [
          {Farmbot.Firmware,
           device: fbos_config.firmware_path,
           transport: Farmbot.Firmware.UARTTransport,
           side_effects: Farmbot.Core.FirmwareSideEffects}
        ]
      else
        []
      end

    children =
      firmware_children ++
        [
          Farmbot.Core.FirmwareEstopTimer
        ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
