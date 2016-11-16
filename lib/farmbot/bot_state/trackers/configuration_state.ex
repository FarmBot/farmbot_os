defmodule Farmbot.BotState.Configuration do
  defmodule State do
    @type t :: %__MODULE__{
      locks: list(String.t),
      configuration: map,
      informational_settings: map
    }
    defstruct [
      locks: [],
      configuration: %{},
      informational_settings: %{},
    ]

    @spec broadcast(t) :: t
    def broadcast(%State{} = state) do
      GenServer.cast(Farmbot.BotState.Monitor, state)
      state
    end
  end

  use GenServer
  require Logger
  def init(_args) do
    {:ok, State.broadcast(%State{})}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end
end
