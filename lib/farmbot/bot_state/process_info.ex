defmodule Farmbot.BotState.ProcessInfo do
  @moduledoc "Info about long running processes."

  defstruct [
    farmwares: %{}
  ]

  @typedoc "State of the Process Info server."
  @type t :: %__MODULE__{
    farmwares: %{optional(Farmware.name) => Farmware.t}
  }

  use Farmbot.BotState.Lib.Partition
end
