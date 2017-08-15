defmodule Farmbot.BotState.Configuration do
  @moduledoc "Externally Editable configuration data"

  defstruct [
    os_auto_update: false,
    steps_per_mm_x: 25,
    steps_per_mm_y: 25,
    steps_per_mm_z: 25
  ]

  @typedoc "Config data"
  @type t :: %__MODULE__{
    os_auto_update: boolean,
    steps_per_mm_x: number,
    steps_per_mm_y: number,
    steps_per_mm_z: number
  }

  use Farmbot.BotState.Lib.Partition
end
