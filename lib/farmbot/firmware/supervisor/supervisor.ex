defmodule Farmbot.Firmware.Supervisor do
  @moduledoc false
  use Supervisor

  @doc "Reinitializes the Firmware stack. Warning has MANY SIDE EFFECTS."
  def reinitialize do
    Farmbot.Firmware.UartHandler.AutoDetector.start_link(:normal, [])
    Supervisor.terminate_child(Farmbot.Bootstrap.Supervisor, Farmbot.Firmware.Supervisor)
  end

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [
      worker(Farmbot.Firmware.EstopTimer, []),
      worker(Farmbot.Firmware, []),
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
