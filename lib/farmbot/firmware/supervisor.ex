defmodule Farmbot.Firmware.Supervisor do
  @moduledoc "Supervises the firmware handler."
  use Supervisor

  @error_msg "Please configure a Firmware handler."

  @doc "Start the Firmware Supervisor."
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    children = [
      worker(Farmbot.Firmware, [])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
