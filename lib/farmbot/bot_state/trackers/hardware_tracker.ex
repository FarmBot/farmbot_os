defmodule Farmbot.BotState.Hardware do
  @moduledoc """
    tracks mcu_params, pins, location
  """

  use GenServer
  require Logger

  defmodule State do
    @moduledoc """
      tracks mcu_params, pins, location
    """

    defstruct [
      location: [-1,-1,-1],
      end_stops: {-1,-1,-1,-1,-1,-1},
      mcu_params: %{},
      pins: %{}
    ]

    @type t :: %__MODULE__{
      location: location,
      end_stops: end_stops,
      mcu_params: mcu_params,
      pins: pins
    }

    @type location :: [number, ...]
    @type mcu_params :: map
    @type pins :: map
    @type end_stops :: {integer,integer,integer,integer,integer,integer}

    @spec broadcast(t) :: t
    def broadcast(%State{} = state) do
      GenServer.cast(Farmbot.BotState.Monitor, state)
      state
    end
  end

  def init(_args) do
    Process.send_after(self(), :params_hack, 3000)
    s = load |> State.broadcast
    {:ok, s}
  end

  @spec load :: State.t
  def load do
    %State{}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_call({:get_pin, pin_number}, _from, %State{} = state) do
    dispatch Map.get(state.pins, Integer.to_string(pin_number)), state
  end

  def handle_call(:get_current_pos, _from, %State{} = state) do
    dispatch state.location, state
  end

  def handle_call(:get_all_mcu_params, _from, %State{} = state) do
    dispatch state.mcu_params, state
  end

  def handle_call({:get_param, param}, _from, %State{} = state) do
    dispatch Map.get(state.mcu_params, param), state
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.error ">> got an unhandled call in " <>
                 "Hardware tracker: #{inspect event}"
    dispatch :unhandled, state
  end

  def handle_cast({:set_pos, {x, y, z}}, %State{} = state) do
    dispatch %State{state | location: [x,y,z]}
  end

  def handle_cast({:set_pin_value, {pin, value}}, %State{} = state) do
    pin_state = state.pins
    new_pin_value =
    case Map.get(pin_state, Integer.to_string(pin)) do
      nil                     ->
        %{mode: -1,   value: value}
      %{mode: mode, value: _} ->
        %{mode: mode, value: value}
    end
    Logger.debug ">> set pin: #{pin}: #{new_pin_value.value}"
    new_pin_state = Map.put(pin_state, Integer.to_string(pin), new_pin_value)
    dispatch %State{state | pins: new_pin_state}
  end

  def handle_cast({:set_pin_mode, {pin, mode}}, %State{} = state) do
    pin_state = state.pins
    new_pin_value =
    case Map.get(pin_state, Integer.to_string(pin)) do
      nil                      -> %{mode: mode, value: -1}
      %{mode: _, value: value} -> %{mode: mode, value: value}
    end
    new_pin_state = Map.put(pin_state, Integer.to_string(pin), new_pin_value)
    dispatch %State{state | pins: new_pin_state}
  end

  def handle_cast({:set_param, {param_string, value}}, %State{} = state) do
    new_params = Map.put(state.mcu_params, param_string, value)
    dispatch %State{state | mcu_params: new_params}
  end

  def handle_cast({:set_end_stops, {xa,xb,ya,yb,za,zc}}, %State{} = state) do
    dispatch %State{state | end_stops: {xa,xb,ya,yb,za,zc}}
  end

  # catch all.
  def handle_cast(event, %State{} = state) do
    Logger.error ">> got an unhandled cast " <>
                 "in Hardware tracker: #{inspect event}"
    dispatch state
  end

  def handle_info(:params_hack, %State{} = state) do
    spawn fn -> Command.read_all_params end
    dispatch state
  end

  defp dispatch(reply, %State{} = state) do
    State.broadcast(state)
    {:reply, reply, state}
  end

  defp dispatch(%State{} = state) do
    State.broadcast(state)
    {:noreply, state}
  end
end
