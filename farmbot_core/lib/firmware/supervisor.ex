defmodule Farmbot.Firmware.Supervisor do
  @moduledoc false
  use Supervisor

  @doc "Reinitializes the Firmware stack. Warning has MANY SIDE EFFECTS."
  def reinitialize do
    Farmbot.Firmware.UartHandler.AutoDetector.start_link([])
    Supervisor.terminate_child(Farmbot.Core, Farmbot.Firmware.Supervisor)
  end

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [
      {Farmbot.Firmware.EstopTimer, []},
      {Farmbot.Firmware, []},
    ]

    Supervisor.init(children, [strategy: :one_for_one])
  end
end
