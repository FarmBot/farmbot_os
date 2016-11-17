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

  # This call should probably be a cast actually, and im sorry.
  # Returns true for configs that exist and are the correct typpe,
  # and false for anything else
  # TODO make sure these are properly typed.
  def handle_call({:update_config, "os_auto_update", value}, _from, %State{} = state)
  when is_boolean(value) do
    new_config = Map.put(state.configuration, :os_auto_update, value)
    dispatch true, %State{configuration: new_config}
  end

  def handle_call({:update_config, "fw_auto_update", value}, _from, %State{} = state)
  when is_boolean(value) do
    new_config = Map.put(state.configuration, :fw_auto_update, value)
    dispatch true, %State{configuration: new_config}
  end

  def handle_call({:update_config, "timezone", value}, _from, %State{} = state)
  when is_bitstring(value) do
    new_config = Map.put(state.configuration, :timezone, value)
    dispatch true, %State{configuration: new_config}
  end

  def handle_call({:update_config, "steps_per_mm", value}, _from, %State{} = state)
  when is_integer(value) do
    new_config = Map.put(state.configuration, :steps_per_mm, value)
    dispatch true, %State{configuration: new_config}
  end

  def handle_call({:update_config, key, _value}, _from, %State{} = state) do
    Logger.error("#{key} is not a valid config.")
    dispatch false, state
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.warn("[#{__MODULE__}] UNHANDLED CALL!: #{inspect event}", [__MODULE__])
    dispatch :unhandled, state
  end

  def handle_cast(event, %State{} = state) do
    Logger.warn("[#{__MODULE__}] UNHANDLED CAST!: #{inspect event}", [__MODULE__])
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
