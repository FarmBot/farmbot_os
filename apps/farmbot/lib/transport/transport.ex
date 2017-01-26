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
               :process_info]

    @type t :: %__MODULE__{
      mcu_params: map,
      location: [integer,...],
      pins: map,
      configuration: map,
      informational_settings: map,
      process_info: map}
  end

  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:producer_consumer, %Serialized{}, subscribe_to: [Monitor]}
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, [], state}

  # FIXME this will cause problems im sure.
  def handle_events(events, _from, state) do
    for event <- events do
      Logger.info "#{__MODULE__} got event: #{inspect event} "
    end
    {:noreply, events, state}
  end

  defp translate(%MonState{} = monstate) do
    %Serialized{
      mcu_params: monstate.hardware.mcu_params,
      location: monstate.hardware.location,
      pins: monstate.hardware.pins,
      configuration: monstate.configuration.configuration,
      informational_settings: monstate.configuration.informational_settings,
      process_info: monstate.process_info
    }
  end

  # Emit a message
  def handle_cast({:emit, thing}, state) do
    # don't Logger this because it will infinate loop.
    # just trust me.
    # logging a message here would cause logger to log a message, which
    # causes a state send which would then emit a message...
    IO.puts "emmitting: #{inspect thing}"
    GenStage.async_notify(__MODULE__, {:emit, thing})
    {:noreply, [], state}
  end

  # Emit a log message
  def handle_cast({:log, log}, state) do
    GenStage.async_notify(__MODULE__, {:log, log})
    {:noreply, [], state}
  end

  def handle_info({_from, %MonState{} = monstate}, _state) do
    new_state = translate(monstate)
    GenStage.async_notify(__MODULE__, {:status, new_state})
    {:noreply, [], new_state}
  end

  def handle_info(event, state) do
    IO.inspect event
    {:noreply, [], state}
  end

  def emit(message), do: GenStage.cast(__MODULE__, {:emit, message})
  def log(message), do: GenStage.cast(__MODULE__, {:log, message})
  def get_state, do: GenServer.call(__MODULE__, :get_state)
end
