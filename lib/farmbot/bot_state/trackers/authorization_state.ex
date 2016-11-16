defmodule Farmbot.BotState.Authorization do
  defmodule State do
    @type t :: %__MODULE__{
      token: map,
      email: String.t,
      pass: String.t,
      server: String.t,
      network: any
    }
    defstruct [
      token: nil,
      email: nil,
      pass: nil,
      server: nil,
      network: nil
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
