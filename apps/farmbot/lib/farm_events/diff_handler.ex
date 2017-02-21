defmodule FarmEvent.DiffHandler do
  @moduledoc """
    Diff handler for FarmEvents
  """
  alias Farmbot.Sync.Database.FarmEvent
  alias Farmbot.Sync.EventManager, as: EM
  alias Farmbot.BotState.ProcessTracker, as: PT

  defmodule DiffHan do
    @moduledoc false
    use GenEvent
    @type state :: pid

    @spec init(pid) :: {:ok, state}
    def init(callback_module), do: {:ok, callback_module}

    @spec handle_event(term, state) :: {:ok, state}
    def handle_event({FarmEvent, diff}, cb) do
      GenServer.cast(cb, {:diff, diff})
      {:ok, cb}
    end

    def handle_event(_, cb), do: {:ok, cb}
  end

  require Logger
  use GenServer

  @type state :: %{}

  @spec start_link :: {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @spec init([]) :: {:ok, state}
  def init([]) do
    :ok = GenEvent.add_mon_handler(EM, DiffHan, self())
    {:ok, %{}}
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_cast({:diff, diff}, state) do
    list = MapSet.to_list(diff)
    Enum.each(list, fn(farm_event) ->
      info = PT.lookup(:farm_event, farm_event.id)
      if info, do: PT.deregister(info.uuid)
      PT.register(:farm_event, "Event-#{farm_event.id}", farm_event)
    end)
    {:noreply, state}
  end

  def handle_info({:gen_event_EXIT, _handler, _reason}, state) do
    :ok = GenEvent.add_mon_handler(EM, DiffHan, self())
    {:noreply, state}
  end

  def terminate(_,_), do: :ok

  @doc """
    Gets the state
  """
  @spec get_state :: state
  def get_state, do: GenServer.call(__MODULE__, :get_state)
end
