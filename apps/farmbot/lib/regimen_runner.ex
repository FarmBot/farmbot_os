alias Farmbot.Sync.Database.Regimen
alias Farmbot.Sync.Database.RegimenItem
use Amnesia
use Regimen
use RegimenItem
use Timex

defmodule Farmbot.RegimenRunner do
  @moduledoc """
    Follows a regimen thru its life.
  """
  defmodule State do
    @moduledoc """
      State of the Regimen Runner
    """
    @enforece_keys []
    defstruct @enforece_keys
    @type t :: %__MODULE__{}
  end

  require Logger
  use GenServer

  @doc """
    Starts a regimen's life. Takes a Regimen and items that have already been
    finished (if this regimen was already running.)
  """
  @spec start_link([Regimen.t]) ::
    {:ok, pid} | {:error, {:already_started, pid}}
  def start_link([%Regimen{} = reg]) do
    name = "Regimen.#{reg.id}" |> String.to_atom
    GenServer.start_link(__MODULE__, reg, name: name)
  end
  def start_link(regimen), do: start_link([regimen])

  @spec init(Regimen.t) :: {:ok, State.t}
  def init(%Regimen{} = reg) do
    start_time = midnight()
    items = reg.id |> get_items() |> sort()
    first_time_offset = List.first(items).time_offset
    f = Timex.shift(start_time, milliseconds: first_time_offset)
    Logger.debug ">> [#{reg.name}] first item will run at: #{f.month}-#{f.day} at #{f.hour}:#{f.minute}"
    {:ok, []}
  end

  def handle_call(:get_state,_, state), do: {:reply, state, state}
  def handle_call(_, _, state), do: {:reply, :unhandled, state}
  def handle_cast(_, state), do: {:noreply, state}
  def handle_info(_, state), do: {:noreply, state}

  @spec get_state(integer) :: State.t
  def get_state(id) do
     name = "Regimen.#{id}" |> String.to_atom
     GenServer.call(name, :get_state)
  end

  @doc """
    Sorts regimen items by the closest time_offset to the farthest away
  """
  @spec sort([RegimenItem.t]) :: [RegimenItem.t]
  def sort(items) do
    Enum.sort(items, &(&1.time_offset <= &2.time_offset))
  end

  @doc """
    Returns a DateTime object of the current time.
  """
  @spec now :: DateTime.t
  def now do
    tz = Farmbot.BotState.get_config :timezone
    Timex.now(tz)
  end

  @doc """
    Returns a DateTime object of midnight today.
    for example if today is july 12 2044 8:14 AM
    this will return: july 12 2044 12:00 AM
  """
  @spec midnight :: DateTime.t
  def midnight do
     Timex.shift(now(),
     [hours: -now().hour, minutes: -now().minute, seconds: -now().second])
  end

  @lint false
  @spec get_items(integer) :: [RegimenItem.t]
  defp get_items(regimen_id_) do
    Amnesia.transaction do
      Farmbot.Sync.Database.RegimenItem.where(regimen_id == regimen_id_)
      |> Amnesia.Selection.values
    end
  end
  _ = @lint # HACK(Connor) fix credo compiler warning
end
