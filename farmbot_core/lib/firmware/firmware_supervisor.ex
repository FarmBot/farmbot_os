defmodule Farmbot.Core.FirmwareSupervisor do
  use Supervisor
  alias Farmbot.Asset

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def reinitialize do
    _ = Supervisor.terminate_child(Farmbot.Core, __MODULE__)
    Supervisor.restart_child(Farmbot.Core, __MODULE__)
  end

  def stub do
    Asset.fbos_config()
    |> Asset.FbosConfig.changeset(%{firmware_path: "stub"})
    |> Asset.Repo.insert_or_update()
  end

  def init([]) do
    fbos_config = Asset.fbos_config()

    children =
      firmware_children(fbos_config) ++
        [
          Farmbot.Core.FirmwareEstopTimer
        ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def firmware_children(%Asset.FbosConfig{firmware_hardware: nil}), do: []

  def firmware_children(%Asset.FbosConfig{firmware_path: "stub"}) do
    [
      {Farmbot.Firmware,
       transport: Farmbot.Firmware.StubTransport, side_effects: Farmbot.Core.FirmwareSideEffects}
    ]
  end

  def firmware_children(%Asset.FbosConfig{firmware_path: nil}), do: []

  def firmware_children(%Asset.FbosConfig{} = fbos_config) do
    [
      {Farmbot.Firmware,
       device: fbos_config.firmware_path,
       transport: Farmbot.Firmware.UARTTransport,
       side_effects: Farmbot.Core.FirmwareSideEffects}
    ]
  end
end
