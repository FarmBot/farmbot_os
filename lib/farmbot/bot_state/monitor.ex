alias Farmbot.BotState.Hardware.State,      as: Hardware
alias Farmbot.BotState.Configuration.State, as: Configuration
alias Farmbot.BotState.Authorization.State, as: Authorization
alias Farmbot.BotState.Network.State,       as: Network
alias Farmbot.Scheduler.State.Serializer,   as: Scheduler

defmodule Farmbot.BotState.Monitor do
  @moduledoc """
    this is the master state tracker. It receives the states from
    various modules, and then pushes updated state to anything that cares
  """
  use GenServer
  require Logger

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
      hardware:      Hardware.t,
      configuration: Configuration.t,
      authorization: Authorization.t,
      network:       Network.t,
      scheduler:     Scheduler.t
    }
    defstruct [
      hardware:      %Hardware{},
      configuration: %Configuration{},
      authorization: %Authorization{},
      network:       %Network{},
      scheduler:     %Scheduler{}
    ]
  end

  def init(mgr) do
    {:ok, {mgr, %State{}}}
  end

  def start_link(mgr) do
    GenServer.start_link(__MODULE__, mgr, name: __MODULE__)
  end

  @doc """
    Adds a handler for getting state updates.
  """
  def add_handler(mgr, module, initial_state)
  when is_atom(module) do
    GenEvent.add_mon_handler(mgr, module, initial_state)
  end

  def add_handler(module, initial_state \\ nil) do
    GenServer.cast(__MODULE__, {:add_handler, module, initial_state})
  end

  def remove_handler(module, args \\ []) do
    GenServer.cast(__MODULE__, {:remove_handler, module, args})
  end

  def remove_handler(mgr, module, args) do
    GenEvent.remove_handler(mgr, module, args)
  end

  def handle_cast({:add_handler, module, initial_state}, {mgr, state}) do
    add_handler(mgr, module, initial_state)
    dispatch(mgr, state)
  end

  def handle_cast({:remove_handler, module, args}, {mgr, state}) do
    remove_handler(mgr, module, args)
    dispatch(mgr, state)
  end

  # When we get a state update from Hardware
  def handle_cast(%Hardware{} = new_things, {mgr, state}) do
    new_state = %State{state | hardware: new_things}
    dispatch(mgr, new_state)
  end

  # When we get a state update from Configuration
  def handle_cast(%Configuration{} = new_things, {mgr, state}) do
    new_state = %State{state | configuration: new_things}
    dispatch(mgr, new_state)
  end

  # When we get a state update from Authorization
  def handle_cast(%Authorization{} = new_things, {mgr, state}) do
    new_state = %State{state | authorization: new_things}
    dispatch(mgr, new_state)
  end

  # When we get a state update from Scheduler
  def handle_cast(%Network{} = new_things, {mgr, state}) do
    new_state = %State{state | network: new_things}
    dispatch(mgr, new_state)
  end

  # When we get a state update from Scheduler
  def handle_cast(%Scheduler{} = new_things, {mgr, state}) do
    new_state = %State{state | scheduler: new_things}
    dispatch(mgr, new_state)
  end

  def handle_cast({:login,
    %{"email" => email,
      "network" => "ethernet",
      "password" => password,
      "server" => server,
      "tz" => timezone}}, {mgr, state})
  do
    Farmbot.BotState.update_config("timezone", timezone)
    Farmbot.BotState.add_creds({email,password,server})
    NetMan.connect(:ethernet, Farmbot.BotState.Network)
    dispatch(mgr,state)
  end

  def handle_cast({:login,
    %{"email" => email,
      "network" => %{"psk" => psk, "ssid" => ssid},
      "password" => password,
      "server" => server,
      "tz" => timezone}}, {mgr, state})
  do
    Farmbot.BotState.update_config("timezone", timezone)
    Farmbot.BotState.add_creds({email,password,server})
    NetMan.connect({ssid, psk}, Farmbot.BotState.Network)
    dispatch(mgr,state)
  end

  def handle_cast(:force_dispatch, {mgr, state}), do: dispatch(mgr, state)

  def handle_cast(new_things, {mgr, state}) do
    Logger.warn("(#{__MODULE__}) WHAT IS THIS??? #{inspect new_things} ")

    dispatch(mgr, state)
  end

  # If a handler dies, we try to restart it
  def handle_info({:gen_event_EXIT, handler, _reason}, {mgr, state}) do
    Logger.warn("HANDLER DIED: #{inspect handler} Goint to try to restart")
    add_handler(mgr, handler)
    dispatch(mgr, state)
  end

  @doc """
    Callback for the genserver in this module
  """
  @spec dispatch(pid | atom, State.t) :: {:noreply, {pid | atom, State.t}}
  def dispatch(mgr, state) do
    GenEvent.notify(mgr, {:dispatch, state})
    {:noreply, {mgr, state}}
  end
end
