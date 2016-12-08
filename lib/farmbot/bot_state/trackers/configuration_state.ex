defmodule Farmbot.BotState.Configuration do
  use GenServer
  require Logger

  defmodule State do
    @type t :: %__MODULE__{
      locks: list(String.t),
      configuration: %{
        os_auto_update: boolean,
        fw_auto_update: boolean,
        timezone:       String.t | nil,
        steps_per_mm:   integer
      },
      informational_settings: %{
        controller_version: String.t,
        private_ip: nil | String.t,
        throttled: String.t,
        target: String.t,
        compat_version: integer,
        environment: :prod | :dev | :test
      }
    }
    defstruct [
      locks: [],
      configuration: %{
        os_auto_update: false,
        fw_auto_update: false,
        timezone:       nil,
        steps_per_mm:   500
      },
      informational_settings: %{
        controller_version: "loading...",
        compat_version: -1,
        target: "loading...",
        environment: :loading,
        private_ip: nil,
        throttled: "loading..."
       },
    ]

    @spec broadcast(t) :: t
    def broadcast(%State{} = state) do
      GenServer.cast(Farmbot.BotState.Monitor, state)
      state
    end
  end

  def init(%{compat_version: compat_version,
             env:            env,
             target:         target,
             version:        version})
  do
    initial_state = %State{
      informational_settings: %{
        controller_version: version,
        compat_version:     compat_version,
        target:             target,
        environment:        env,
        throttled:          get_throttled
      }}
      state = load(initial_state)
    {:ok, State.broadcast(state)}
  end

  def load(initial_state) do
    case SafeStorage.read(__MODULE__) do
      {:ok, %State{} = last_state} ->
        Logger.debug ">> is loading previous configuration."
        # Merge the last state
        %State{initial_state | configuration: last_state.configuration}
        # Maybe persiste locks?
      _ ->
        initial_state
    end
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
    new_state = %State{state | configuration: new_config}
    save(new_state)
    dispatch true, new_state
  end

  def handle_call({:update_config, "fw_auto_update", value}, _from, %State{} = state)
  when is_boolean(value) do
    new_config = Map.put(state.configuration, :fw_auto_update, value)
    new_state = %State{state | configuration: new_config}
    save(new_state)
    dispatch true, new_state
  end

  def handle_call({:update_config, "timezone", value}, _from, %State{} = state)
  when is_bitstring(value) do
    new_config = Map.put(state.configuration, :timezone, value)
    new_state = %State{state | configuration: new_config}
    save(new_state)
    dispatch true, new_state
  end

  def handle_call({:update_config, "steps_per_mm", value}, _from, %State{} = state)
  when is_integer(value) do
    new_config = Map.put(state.configuration, :steps_per_mm, value)
    new_state = %State{state | configuration: new_config}
    save(new_state)
    dispatch true, new_state
  end

  def handle_call({:update_config, key, _value}, _from, %State{} = state) do
    Logger.error ">> got an invalid configuration in Configuration tracker: #{inspect key}"
    dispatch false, state
  end

  # Allow the frontend to do stuff again.
  def handle_call({:remove_lock, string}, _from,  %State{} = state) do
    maybe_index = Enum.find_index(state.locks, fn(%{reason: str}) -> str == string end)
    cond do
      is_integer(maybe_index) ->
        new_state = %State{state | locks: List.delete_at(state.locks, maybe_index)}
        dispatch :ok, new_state
      true ->
        dispatch {:error, :no_index}, state
    end
  end

  def handle_call({:get_lock, string}, _from, %State{} = state) do
    maybe_index = Enum.find_index(state.locks, fn(%{reason: str}) -> str == string end)
    dispatch(maybe_index, state)
  end

  def handle_call(:get_version, _from, %State{} = state) do
    dispatch(state.informational_settings.controller_version, state)
  end

  def handle_call({:get_config, key}, _from, %State{} = state)
  when is_atom(key) do
    dispatch Map.get(state.configuration, key), state
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.error ">> got an unhandled call in Configuration tracker: #{inspect event}"
    dispatch :unhandled, state
  end

  def handle_cast({:update_info, key, value}, %State{} = state) do
    new_info = Map.put(state.informational_settings, key, value)
    new_state = %State{state | informational_settings: new_info }
    dispatch new_state
  end

  # Lock the frontend from doing stuff
  def handle_cast({:add_lock, string}, %State{} = state) do
    maybe_index = Enum.find_index(state.locks, fn(%{reason: str}) -> str == string end)
    # check if this lock already exists.
    cond do
      # this lock already exists. don't do anything.
      is_integer(maybe_index) ->
        dispatch state
      # This lock does not exist. (the check is nil). add a new lock.
      is_nil(maybe_index) ->
        new_state = %State{locks: state.locks ++ [%{reason: string}]}
        dispatch new_state
    end
  end

  def handle_cast(event, %State{} = state) do
    Logger.error ">> got an unhandled cast in Configuration: #{inspect event}"
    dispatch state
  end

  def save(%State{} = state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
  end

  defp dispatch(reply, %State{} = state) do
    State.broadcast(state)
    {:reply, reply, state}
  end

  defp dispatch(%State{} = state) do
    State.broadcast(state)
    {:noreply, state}
  end

  defp get_throttled do
      {output, 0} = System.cmd("vcgencmd", ["get_throttled"])
      {"throttled=0x0\n", 0}
      [_, throttled] = output
      |> String.strip
      |> String.split("=")
      throttled
  end
end
