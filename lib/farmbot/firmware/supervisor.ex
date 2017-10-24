defmodule Farmbot.Firmware.Supervisor do
  @moduledoc false
  use Supervisor

  @doc false
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
