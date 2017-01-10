alias Experimental.GenStage
alias Farmbot.BotState.Monitor
alias Farmbot.BotState.Monitor.State, as: MonState
defmodule Farmbot.Transport do
  @moduledoc """
    Serializes Farmbot's state to be send out to any subscribed transports.
  """
  use GenStage
  require Logger

  defmodule Serialized do
    @moduledoc false
    defstruct [:mcu_params,
               :location,
               :pins,
               :configuration,
               :informational_settings,
               :farm_scheduler]

    @type t :: %__MODULE__{
      mcu_params: map,
      location: [integer,...],
      pins: map,
      configuration: map,
      informational_settings: map,
      farm_scheduler: map
    }
  end

  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:producer_consumer, %Serialized{}, subscribe_to: [Monitor]}
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, [], state}

  # FIXME this will cause problems im sure.
  def handle_events(events, _from, _state) do
    blah = Enum.map(events, fn(event) ->
      do_handle(event)
    end)
    new_state = List.last(blah)
    {:noreply, [new_state], new_state}
  end

  defp do_handle(%MonState{} = monstate) do
    %Serialized{
      mcu_params: monstate.hardware.mcu_params,
      location: monstate.hardware.location,
      pins: monstate.hardware.pins,
      configuration: monstate.configuration.configuration,
      informational_settings: monstate.configuration.informational_settings,
      farm_scheduler: nil
    }
  end

  # Emit a binary
  def handle_cast({:emit, binary}, state) do
    {:noreply, [{:emit, binary}], state}
  end

  # Emit a log message
  def handle_cast({:log, binary}, state) do
    {:noreply, [{:log, binary}], state}
  end

  def emit(message) do
    GenStage.cast(__MODULE__, {:emit, message})
  end

  def log(message) do
    GenStage.cast(__MODULE__, {:log, message})
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end
end
