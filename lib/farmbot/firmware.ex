defmodule Farmbot.Firmware do
  @moduledoc "Allows communication with the firmware."

  use GenServer
  require Logger

  alias Farmbot.BotState
  alias Farmbot.BotState.{
    InformationalSettings,
    LocationData
  }

  @doc "Public API for handling a gcode."
  def handle_gcode(firmware, code), do: GenServer.call(firmware, {:handle_gcode, code})

  def start_link(bot_state, informational_settings, configuration, location_data, mcu_params, handler_mod, opts) do
    GenServer.start_link(__MODULE__, [bot_state, informational_settings, configuration, location_data, mcu_params, handler_mod], opts)
  end

  defmodule State do
    defstruct [
      :bot_state,
      :informational_settings,
      :configuration,
      :location_data,
      :mcu_params,
      :handler_mod,
      :handler
    ]
  end

  def init([bot_state, informational_settings, configuration, location_data, mcu_params, handler_mod]) do
    {:ok, handler} = handler_mod.start_link(self(), name: handler_mod)
    Process.link(handler)
    s = %State{
      bot_state: bot_state,
      informational_settings: informational_settings,
      configuration: configuration,
      location_data: location_data,
      mcu_params: mcu_params,
      handler_mod: handler_mod,
      handler: handler
    }
    {:ok, s}
  end

  def handle_call({:handle_gcode, :idle}, _, state) do
    reply = InformationalSettings.set_busy(state.informational_settings, false)
    {:reply, reply, state}
  end

  def handle_call({:handle_gcode, {:report_current_position, x, y, z}}, _, state) do
    reply = LocationData.report_current_position(state.location_data, x, y, z)
    {:reply, reply, state}
  end

  def handle_call({:handle_gcode, {:report_encoder_position_scaled, x, y, z}}, _, state) do
    reply = LocationData.report_encoder_position_scaled(state.location_data, x, y, z)
    {:reply, reply, state}
  end

  def handle_call({:handle_gcode, {:report_encoder_position_raw, x, y, z}}, _, state) do
    reply = LocationData.report_encoder_position_raw(state.location_data, x, y, z)
    {:reply, reply, state}
  end

  def handle_call({:handle_gcode, {:report_end_stops, xa, xb, ya, yb, za, zb}}, _, state) do
    reply = LocationData.report_end_stops(state.location_data, xa, xb, ya, yb, za, zb)
    {:reply, reply, state}
  end

  def handle_call({:handle_gcode, code}, _, state) do
    Logger.warn "Got misc gcode: #{inspect code}"
    {:reply, {:error, :unhandled}, state}
  end
end
