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

  def update_farmwares(part, farmwares) do
    GenServer.cast(part, {:update_farmwares, farmwares})
  end

  def partition_cast({:update_farmwares, farmwares}, state) do
    {:noreply, %{state | farmwares: farmwares}}
  end
end
