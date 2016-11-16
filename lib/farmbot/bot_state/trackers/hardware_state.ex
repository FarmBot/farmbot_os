defmodule Farmbot.BotState.Hardware do
  @moduledoc """
    tracks mcu_params, pins, location
  """
  defmodule State do
    @moduledoc """
      tracks mcu_params, pins, location
    """

    defstruct [
      location: [-1,-1,-1],
      mcu_params: %{},
      pins: %{}
    ]

    @type t :: %__MODULE__{
      location: location,
      mcu_params: mcu_params,
      pins: pins
    }

    @type location :: [number, ...]
    @type mcu_params :: map
    @type pins :: map

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
