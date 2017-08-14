defmodule Farmbot.BotState.ProcessInfo do
  @moduledoc "Info about long running processes."
  
  defstruct [
    farmwares: %{}
  ]
  
  @typedoc "State of the Process Info server."
  @type t :: %__MODULE__{
    farmwares: %{optional(Farmware.name) => Farmware.t}
  }

  use GenServer
  require Logger
  
  @doc "Start the ProcessInfo server."
  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args) do
    {:ok, %__MODULE__{}}
  end
end
