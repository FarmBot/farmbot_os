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
  alias Farmbot.RegimenRunner
  alias Farmbot.Context

  defmodule Info do
    @moduledoc false
    defstruct [:name, :uuid, :status, :stuff]
    @typedoc """
      Status of this process
    """
    @type status :: atom
    @type stuff :: any
    @type kind :: :regimen | :farmware
    @type t ::
      %__MODULE__{name: String.t, uuid: binary, status: status, stuff: stuff}
  end

  defmodule State do
    @moduledoc false
    defstruct [regimens: [], farmwares: [], context: nil]
    @type uuid :: binary
    @type kind :: :farmware | :regimen
    @type t ::
      %__MODULE__{
        regimens:    [Info.t],
        farmwares:   [Info.t],
        context: Context.t
      }
  end

  def init(%Context{} = ctx), do: {:ok, %State{context: ctx}}

  @doc """
    Starts the Process Tracker
  """
  def start_link(%Context{} = context, opts),
     do: GenServer.start_link(__MODULE__, context, opts)

  @doc """
    Registers a kind, name with a database entry to be tracked
  """
  @spec register(Context.t, State.kind, String.t, map) :: no_return
  def register(%Context{} = context, kind, name, stuff) do
    GenServer.cast(context.process_tracker, {:register, kind, name, stuff})
  end

  @doc """
    DeRegisters a pid.
  """
  @spec deregister(Context.t, State.uuid) :: no_return
  def deregister(%Context{} = context, uuid),
    do: GenServer.cast(context.process_tracker, {:deregister, uuid})

  @doc """
    starts a process by its uuid or info struct
  """
  @spec start_process(Context.t, State.uuid | Info.t) :: {:ok, pid} | {:error, term}
  def start_process(%Context{} = ctx, %Info{uuid: uuid}), do: start_process(ctx, uuid)
  def start_process(%Context{} = ctx, uuid),
    do: GenServer.call(ctx.process_tracker, {:start_process, uuid})

  @doc """
    Stops a process by it's uuid.
  """
  @spec stop_process(Context.t, State.uuid) :: :ok | {:error, term}
  def stop_process(%Context{} = ctx, uuid),
    do: GenServer.call(ctx.process_tracker, {:stop_process, uuid})

  @doc """
    Lookup a uuid by its kind and name
  """
  @spec lookup(Context.t, State.kind, String.t) :: Info.t
  def lookup(%Context{} = ctx, kind, name) do
    GenServer.call(ctx.process_tracker, {:lookup, kind, name})
  end

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
      r = mod.start_process(info.stuff)
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
      r = key_to_module(key).stop_process(info.stuff)
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
  def terminate(_reason, _state), do: :ok

  @spec nest_the_loops(State.uuid, State.t) :: {State.kind, Info.t} | nil
  defp nest_the_loops(uuid, state) do
    # I have to enumerate over all the processes "kind"s here...
    # this is the most javascript elixir i have ever wrote.
    # loop over all the keys
    Enum.find_value(Map.from_struct(state), fn({key, value}) ->
        # loop over the values of those keys/kinds
        Enum.find_value(value, fn(info) ->
          do_find(uuid, info, key)
        end)
    end)
  end

  defp do_find(uuid, info, key) do
    if uuid == info.uuid do
      # return the kind and the info
      {key, info}
    else
      false
    end
  end

  @spec dispatch(State.t) :: {:noreply, State.t}
  defp dispatch(state) do
    cast(state)
    {:noreply, state}
  end

  @spec dispatch(term, State.t) :: {:reply, term, State.t}
  defp dispatch(reply, state) do
    cast(state)
    {:reply, reply, state}
  end

  @spec cast(State.t) :: no_return
  defp cast(state), do: GenServer.cast(state.context.monitor, state)

  @spec kind_to_key(any) :: :regimens | :farmwares | no_return
  defp kind_to_key(:regimen), do: :regimens
  defp kind_to_key(:farmware), do: :farmwares

  @spec key_to_module(any) :: Farmware | RegimenRunner
  defp key_to_module(:regimens), do: RegimenRunner
  defp key_to_module(:farmwares), do: Farmware
end
