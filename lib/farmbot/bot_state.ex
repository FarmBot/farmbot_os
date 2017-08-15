defmodule Farmbot.BotState do
  @moduledoc """
  State tree of the bot.
  """
  alias Farmbot.BotState.{
    Configuration,
    InformationalSettings,
    Job,
    LocationData,
    McuParams,
    Pin,
    ProcessInfo
  }

  defstruct [
    configuration: %Configuration{},
    informational_settings: %InformationalSettings{},
    location_data: %LocationData{},
    mcu_params: %McuParams{},
    process_info: %ProcessInfo{},
    jobs: %{},
    pins: %{},
    user_env: %{},
  ]

  @typedoc "Bot State"
  @type t :: %__MODULE__{
    informational_settings: InformationalSettings.t,
    configuration: Configuration.t,
    location_data: LocationData.t,
    process_info:  ProcessInfo.t,
    mcu_params:    McuParams.t,
    jobs:     %{optional(binary) => Job.t},
    pins:     %{optional(number) => Pin.t},
    user_env: %{optional(binary) => binary}
  }

  @typedoc "Instance of this module."
  @type state_server :: GenServer.server

  @doc """
  Subscribe to updates from the bot.

  ## Updates
  Updates will come in randomly in the shape of
  `{:bot_state, state}` where state is a BotState struct.
  """
  @spec subscribe(state_server) :: :ok | {:error, :already_subscribed}
  def subscribe(state_tracker) do
    GenServer.call(state_tracker, :subscribe)
  end

  @doc """
  Unsubscribes from the bot state tracker.
  returns a boolean where true means the called pid was
  actually subscribed and false means it was not actually subscribed.
  """
  @spec unsubscribe(state_server) :: boolean
  def unsubscribe(state_tracker) do
    GenServer.call(state_tracker, :unsubscribe)
  end

  @doc "Forces a dispatch to all the clients."
  @spec force_dispatch(state_server) :: :ok
  def force_dispatch(state_server) do
    GenServer.call(state_server, :force_dispatch)
  end

  ## GenServer

  use GenServer
  require Logger

  # these modules have seperate process backing them.
  @update_mods [InformationalSettings, Configuration, LocationData, ProcessInfo, McuParams]

  defmodule PrivateState do
    @moduledoc "State for the GenServer."

    defstruct [
      subscribers: [],
      bot_state: %Farmbot.BotState{}
    ]

    @typedoc "Private State."
    @type t :: %__MODULE__{subscribers: [GenServer.server],
                           bot_state: Farmbot.BotState.t}
  end

  @doc "Start the Bot State Server."
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:ok, %PrivateState{}}
  end

  # This is the signature of an update to a key in the bot's state.
  # Only except updates from module backed by a process somewhere.
  def handle_cast({:update, module, value}, priv) when module in @update_mods do
    ["Farmbot", "BotState", camel] = Module.split(module)
    new_bot_state = %{priv.bot_state | :"#{Macro.underscore(camel)}" => value}
    dispatch priv, new_bot_state
  end

  def handle_call(:subscribe, {pid, _ref}, priv) do
    # Checks if this pid is already subscribed.
    if pid in priv.subscribers do
      {:reply, {:error, :already_subscribed}, priv}
    else
      send pid, {:bot_state, priv.bot_state}
      {:reply, :ok, %{priv | subscribers: [pid | priv.subscribers]}}
    end
  end

  def handle_call(:unsubscribe, {pid, _ref}, %{subscribers: subs} = priv) do
    actually_removed = pid in subs
    {:reply, actually_removed, %{priv | subscribers: List.delete(subs, pid)}}
  end

  def handle_call(:force_dispatch, _from, priv) do
    dispatch priv, priv.bot_state
    {:reply, :ok, priv}
  end

  # Dispatches a new state to all the subscribers.
  defp dispatch(%PrivateState{subscribers: subs} = priv, %__MODULE__{} = new) do
    for sub <- subs do
      send sub, {:bot_state, new}
    end
    {:noreply, %{priv | bot_state: new}}
  end
end
