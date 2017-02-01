alias Farmbot.BotState.Hardware.State,      as: Hardware
alias Farmbot.BotState.Configuration.State, as: Configuration
alias Farmbot.BotState.ProcessTracker, as: PT
defmodule Farmbot.BotState.Monitor do
  @moduledoc """
    this is the master state tracker. It receives the states from
    various modules, and then pushes updated state to anything that cares
  """
  use GenStage
  require Logger

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
      hardware:      Hardware.t,
      configuration: Configuration.t,
      process_info: PT.t
    }
    defstruct [
      hardware:      %Hardware{},
      configuration: %Configuration{},
      process_info:  %PT.State{}
    ]
  end

  @doc """
    Starts the state producer.
  """
  def start_link, do: GenStage.start_link(__MODULE__, [], name: __MODULE__)
  def init([]), do: {:producer, %State{}}

  def handle_demand(_demand, state), do: dispatch state

  # When we get a state update from Hardware
  def handle_cast(%Hardware{} = new_things, %State{} = state) do
    new_state = %State{state | hardware: new_things}
    dispatch(new_state)
  end

  # When we get a state update from Configuration
  def handle_cast(%Configuration{} = new_things, %State{} = state) do
    new_state = %State{state | configuration: new_things}
    dispatch(new_state)
  end

  def handle_cast(%PT.State{} = new_things, %State{} = state) do
    new_state = %State{state | process_info: new_things}
    dispatch(new_state)
  end

  def handle_call(:get_state,_, state), do: dispatch(state, state)

  @doc """
    Gets the current accumulated state.
  """
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  @spec dispatch(State.t) :: {:noreply, [], State.t }
  defp dispatch(%State{} = state) do
    GenStage.async_notify(__MODULE__, state)
    {:noreply, [], state}
  end
  @spec dispatch(any, State.t) :: {:reply, any, [], State.t }
  defp dispatch(reply, state) do
    GenStage.async_notify(__MODULE__, state)
    {:reply, reply, [], state}
  end
end
