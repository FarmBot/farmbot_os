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

  def handle_events([%MonState{} = monstate], _from, _) do
    Logger.debug ">> Got state update"
    new_state = %Serialized{
      mcu_params: monstate.hardware.mcu_params,
      location: monstate.hardware.location,
      pins: monstate.hardware.pins,
      configuration: monstate.configuration.configuration,
      informational_settings: monstate.configuration.informational_settings,
      farm_scheduler: nil
    }
    {:noreply, [new_state], new_state}
  end

  def handle_events(t, _, state) do
    Logger.warn "FIX THIS: #{inspect t}"
    {:noreply, [nil], state}
  end

  def handle_cast({:emit, binary}, state) do
    {:noreply, [{:emit, binary}], state}
  end

  def handle_cast({:log, binary}, state) do
    {:noreply, [{:log, binary}], state}
  end

  def emit(message) do
    GenStage.cast(__MODULE__, {:emit, message})
  end

  def log(message) do
    GenStage.cast(__MODULE__, {:log, message})
  end
end
