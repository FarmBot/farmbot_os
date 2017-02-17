defmodule Farmbot.BotState.ProcessTracker do
  @moduledoc """
    Module responsible for `process_info` in the BotState tree.

    These will be the "user accessable" processes to control.
    FarmbotJS will see the uuids here. If they are registered, that does not
    mean they are running.
  """
  use GenServer
  require Logger
  alias Nerves.Lib.UUID

  defmodule Info do
    @moduledoc false
    defstruct [:name, :uuid, :status, :stuff]
    @typedoc """
      Status of this process
    """
    @type status :: atom
    @type kind :: :event | :farmware | :regimen
    @type t ::
      %__MODULE__{name: String.t, uuid: binary, status: status, stuff: map}
  end

  defmodule State do
    @moduledoc false
    defstruct [events: [], regimens: [], farmwares: []]
    @type uuid :: binary
    @type kind :: :event | :farmware | :regimen
    @type t ::
      %__MODULE__{
        events:    [Info.t],
        regimens:  [Info.t],
        farmwares: [Info.t]}
  end

  @spec init([]) :: {:ok, State.t}
  def init([]), do: {:ok, %State{}}

  @doc """
    Starts the Process Tracker
  """
  @spec start_link :: {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc """
    Registers a kind, name with a database entry to be tracked
  """
  @spec register(State.kind, String.t, map) :: no_return
  def register(kind, name, stuff) do
    GenServer.cast(__MODULE__, {:register, kind, name, stuff})
  end

  @doc """
    DeRegisters a pid.
  """
  @spec deregister(State.uuid) :: no_return
  def deregister(uuid), do: GenServer.cast(__MODULE__, {:deregister, uuid})

  @doc """
    starts a process by its uuid or info struct
  """
  @spec start_process(State.uuid | Info.t) :: {:ok, pid} | {:error, term}
  def start_process(%Info{uuid: uuid}), do: start_process(uuid)
  def start_process(uuid),
    do: GenServer.call(__MODULE__, {:start_process, uuid})

  @doc """
    Stops a process by it's uuid.
  """
  @spec stop_process(State.uuid) :: :ok | {:error, term}
  def stop_process(uuid),
    do: GenServer.call(__MODULE__, {:stop_process, uuid})

  @doc """
    Lookup a uuid by its kind and name
  """
  @spec lookup(State.kind, String.t) :: Info.t
  def lookup(kind, name) do
    GenServer.call(__MODULE__, {:lookup, kind, name})
  end

  @doc """
    Gets the state of the tracker.
  """
  @spec get_state :: State.t
  def get_state, do: GenServer.call(__MODULE__, :state)

  # GenServer stuffs

  def handle_call({:lookup, kind, name}, _, state) do
    key = kind_to_key(kind)
    list = Map.get(state, key)
    f = Enum.find(list, fn(info) -> info.name == name end)
    dispatch(f, state)
  end

  def handle_call({:start_process, uuid}, _, state) do
    thing = nest_the_loops(uuid, state)
    if thing do
      {key, info} = thing
      Logger.info ">> is starting a #{key} #{info.name}"
      mod = key_to_module(key)
      r = mod.execute(info.stuff)
      # TODO(Connor) update status here
      dispatch(r, state)
    else
      Logger.info ">> could not find #{uuid} to start!"
      dispatch({:error, :no_uuid}, state)
    end
  end

  def handle_call({:stop_process, uuid}, _, state) do
    thing = nest_the_loops(uuid, state)
    if thing do
      {key, info} = thing
      Logger.info ">> is stoping a #{key} #{info.name}"
      r = key_to_module(key).stop(info.uuid)
      # update status here
      dispatch(r, state)
    else
      Logger.info ">> could not find #{uuid} to stop!"
      dispatch({:error, :no_uuid}, state)
    end
  end

  def handle_call(:state, _, state), do: dispatch(state, state)
  def handle_call(_call, _, state), do: dispatch(:no, state)

  def handle_cast({:register, kind, name, stuff}, state) do
    Logger.info ">> is registering a #{kind} as #{name}"
    uuid = UUID.generate
    key = kind_to_key(kind)
    new_list = [
      %Info{name: name,
        uuid: uuid,
        status: :not_running,
        stuff: stuff} | Map.get(state, key)]

    new_state = %{state | key => new_list}
    dispatch(new_state)
  end

  def handle_cast({:deregister, uuid}, state) do
    thing = nest_the_loops(uuid, state)
    if thing do
      {kind, info} = thing
      Logger.info ">> is deregistering #{uuid} #{kind} #{info.name}"
      list = Map.get(state, kind)
      new_list = List.delete(list, info)
      dispatch(%{state | kind => new_list})
    else
      Logger.info ">> could not find #{uuid}"
      dispatch(state)
    end
  end

  def handle_cast(_cast, _, state), do: dispatch(state)
  def handle_info(_info, _, state), do: dispatch(state)
  def terminate(_reason, _state), do: :ok #TODO(connor) save the state here?

  @spec nest_the_loops(State.uuid, State.t) :: {State.kind, Info.t} | nil
  @lint {Credo.Check.Refactor.Nesting, false}
  defp nest_the_loops(uuid, state) do
    # I have to enumerate over all the processes "kind"s here...
    # this is the most javascript elixir i have ever wrote.
    # loop over all the keys
    Enum.find_value(Map.from_struct(state), fn({key, value}) ->
        # loop over the values of those keys/kinds
        Enum.find_value(value, fn(info) ->
          if uuid == info.uuid do
            # return the kind and the info
            {key, info}
          else
            false
          end
        end)
    end)
  end
  # END END END END END END # LOL
    _ = @lint

  @spec dispatch(State.t) :: {:noreply, State.t}
  defp dispatch(state) do
    cast(state)
    {:noreply, state}
  end

  @spec dispatch(any, State.t) :: {:reply, any, State.t}
  defp dispatch(reply, state) do
    cast(state)
    {:reply, reply, state}
  end

  @spec cast(State.t) :: no_return
  defp cast(state), do: GenServer.cast(Farmbot.BotState.Monitor, state)

  @spec kind_to_key(any) :: :events | :regimens | :farmwares | no_return
  defp kind_to_key(:event), do: :events
  defp kind_to_key(:regimen), do: :regimens
  defp kind_to_key(:farmware), do: :farmwares

  @spec key_to_module(any) :: Farmware | RegimenRunner | :TODO | no_return
  defp key_to_module(:events), do: :TODO
  defp key_to_module(:regimens), do: RegimenRunner
  defp key_to_module(:farmwares), do: Farmware
end
