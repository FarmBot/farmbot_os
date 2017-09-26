defmodule Farmbot.BotState.Configuration do
  @moduledoc "Externally Editable configuration data"
  alias Farmbot.System.ConfigStorage, as: CS

  defstruct [
    os_auto_update: false,
    first_party_farmware: true,
    timezone: nil
  ]

  @typedoc "Config data"
  @type t :: %__MODULE__{
    os_auto_update: boolean,
    first_party_farmware: boolean,
    timezone: binary | nil
  }

  use Farmbot.BotState.Lib.Partition

  def save_state(%__MODULE__{} = pub) do
    CS.update_config_value(:bool, "settings", "os_auto_update", pub.os_auto_update)
    CS.update_config_value(:bool, "settings", "first_party_farmware", pub.first_party_farmware)
    CS.update_config_value(:string, "settings", "timezone", pub.timezone)
  end
end
