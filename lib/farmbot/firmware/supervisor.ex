defmodule Farmbot.Firmware.Supervisor do
  @moduledoc "Supervises the firmware handler."
  use Supervisor

  @error_msg "Please configure a Firmware handler."

  @doc "Start the Firmware Supervisor."
  def start_link(bot_state, informational_settings, configuration, location_data, mcu_params, opts \\ []) do
    Supervisor.start_link(__MODULE__, [bot_state, informational_settings, configuration, location_data, mcu_params], opts)
  end

  def init([bot_state, informational_settings, configuration, location_data, mcu_params]) do
    handler_mod = Application.get_env(:farmbot, :behaviour)[:firmware] || raise @error_msg
    children = [
      worker(Farmbot.Firmware, [bot_state, informational_settings, configuration, location_data, mcu_params, handler_mod, [name: Farmbot.Firmware]])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
