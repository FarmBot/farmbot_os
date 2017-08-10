defmodule Farmbot.Firmware.Supervisor do
  @moduledoc "Supervises the firmware handler."
  use Supervisor

  @doc "Start the Firmware Supervisor."
  def start_link(args, opts \\ []) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    children = [

    ]
    opts = [strategy: :one_for_one]
  end
end
