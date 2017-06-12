alias Farmbot.BotState.Hardware.State,      as: Hardware
alias Farmbot.BotState.Configuration.State, as: Configuration
alias Farmbot.Farmware.Manager.State,       as: FarmwareManagerState
defmodule Farmbot.BotState.Monitor do
  @moduledoc """
    this is the master state tracker. It receives the states from
    various modules, and then pushes updated state to anything that cares
  """
  use GenStage
  require Logger
  alias Farmbot.Context

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
      context:       Context.t,
      hardware:      Hardware.t,
      configuration: Configuration.t,
      process_info:  %{
        farmwares: %{name: binary, uuid: binary, version: binary}
      }
    }
    defstruct [
      context:       nil,
      hardware:      %Hardware{},
      configuration: %Configuration{},
      process_info:  %{farmwares: %{}}
    ]
  end

  @doc """
    Starts the state producer.
  """
  def start_link(%Context{} = ctx, opts), do: GenStage.start_link(__MODULE__, ctx, opts)

  def init(context), do: {:producer, %State{context: context}}

  def handle_demand(_demand, old_state), do: dispatch old_state

  # When we get a state update from Hardware
  def handle_cast(%Hardware{} = new_things, %State{} = old_state) do
    new_state = %State{old_state | hardware: new_things}
    dispatch(new_state)
  end

  # When we get a state update from Configuration
  def handle_cast(%Configuration{} = new_things, %State{} = old_state) do
    new_state = %State{old_state | configuration: new_things}
    dispatch(new_state)
  end

  def handle_cast(%FarmwareManagerState{farmwares: fws}, %State{} = old_state) do
    new_process_info = %{old_state.process_info | farmwares: fws}
    new_state        = %{old_state | process_info: new_process_info}
    dispatch(new_state)
  end

  @spec dispatch(State.t) :: {:noreply, [], State.t }
  defp dispatch(%State{} = new_state) do
    GenStage.async_notify(new_state.context.monitor, new_state)
    {:noreply, [], new_state}
  end
end
