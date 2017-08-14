defmodule Farmbot.BotState do
  @moduledoc """
  State tree of the bot.
  """
  alias Farmbot.BotState.{
    Configuration,
    InformationalSettings,
    Job,
    LocationData,
    McuParams,
    Pin,
    ProcessInfo
  }

  defstruct [
    configuration: %Configuration{},
    informational_settings: %InformationalSettings{},
    jobs: %{},
    location_data: %LocationData{},
    mcu_params: %McuParams{},
    pins: %{},
    process_info: %ProcessInfo{},
    user_env: %{},
  ]
  
  @typedoc "Bot State"
  @type t :: %__MODULE__{
    configuration: Configuration.t,
    informational_settings: InformationalSettings.t,
    jobs: %{optional(binary) => Job.t},
    location_data: LocationData.t,
    pins: %{optional(number) => Pin.t},
    process_info: ProcessInfo.t,
    user_env: %{optional(binary) => binary}
  }

end
