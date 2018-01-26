defmodule Farmbot.Firmware.Supervisor do
  @moduledoc false
  use Supervisor

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [
      worker(Farmbot.Firmware.EstopTimer, []),
      worker(Farmbot.Firmware, [])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
