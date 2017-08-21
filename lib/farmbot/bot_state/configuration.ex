defmodule Farmbot.BotState.Configuration do
  @moduledoc "Externally Editable configuration data"

  defstruct [
    os_auto_update: false,
  ]

  @typedoc "Config data"
  @type t :: %__MODULE__{
    os_auto_update: boolean,
  }

  use Farmbot.BotState.Lib.Partition
end
