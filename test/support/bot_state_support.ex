defmodule Farmbot.BotStateSupport do
  @moduledoc "Helpers for starting the BotState stack."
  alias Farmbot.BotState
  alias Farmbot.BotState.{
    InformationalSettings, Configuration, LocationData, ProcessInfo, McuParams,
  }

  def start_bot_state_stack do
    {:ok, bot_state} = BotState.start_link([])
    {:ok, info_settings} =  InformationalSettings.start_link(bot_state, [])
    {:ok, config} = Configuration.start_link(bot_state, [])
    {:ok, loc_data} =  LocationData.start_link(bot_state, [])
    {:ok, proc_info} = ProcessInfo.start_link(bot_state, [])
    {:ok, mcu_params} = McuParams.start_link(bot_state, [])
    %{
      bot_state: bot_state,
      informational_settings: info_settings,
      configuration: config,
      location_data: loc_data,
      process_info: proc_info,
      mcu_params: mcu_params
    }
  end
end
