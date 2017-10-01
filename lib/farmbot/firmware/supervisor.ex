defmodule Farmbot.Firmware.Supervisor do
  @moduledoc "Supervises the firmware handler."
  use Supervisor

  @error_msg "Please configure a Firmware handler."

  @doc "Start the Firmware Supervisor."
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    handler_mod = Application.get_env(:farmbot, :behaviour)[:firmware_handler] || raise @error_msg
    children = [
      worker(handler_mod, [[name: handler_mod]]),
      worker(Farmbot.Firmware, [[name: Farmbot.Firmware]])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
