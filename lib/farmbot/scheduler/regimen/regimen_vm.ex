defmodule Scheduler.Regimen.VM  do
  alias Farmbot.Sync.Database.Regimen, as: Regimen
  alias Farmbot.Sync.Database.RegimenItem, as: RegimenItem
  use Amnesia
  use RegimenItem
  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
      flag: Farmbot.Scheduler.State.regimen_flag,
      timer: reference,
      start_time: DateTime.t,
      regimen_items: list(RegimenItem.t),
      ran_items: list(RegimenItem.t),
      regimen: Regimen.t
    }

    defstruct [
      flag: :normal,
      timer: nil,
      start_time: nil,
      regimen_items: [],
      ran_items: [],
      regimen: nil]
  end

  @checkup_time 15000 #TODO: change this to 60 seconds
  require Logger

  @spec start_link(Regimen.t,list(RegimenItem.t), DateTime.t) :: {:ok, pid} | {:error, {:already_started, pid}}
  def start_link(regimen, finished_items, time) do
    GenServer.start_link(__MODULE__, {regimen, finished_items, time})
  end

  @spec init({Regimen.t, list(RegimenItem.t), DateTime.t}) :: {:ok, map}
  def init({%Regimen{} = regimen, finished_items, time}) do
    items = get_regimen_item_for_regimen(regimen)
    first = List.first(items -- finished_items)
    first_time = Timex.shift(time, milliseconds: first.time_offset)

    # Remove this one day
    Logger.warn("""
    \n
    \t\t the first item will execute on:
    \t\t #{first_time.month}-#{first_time.day}
    \t\t at: #{first_time.hour}:#{first_time.minute}
    """)

    initial_state = %State{
      flag: :normal,
      timer: tick(self()),
      start_time: time,
      regimen_items: items -- finished_items,
      ran_items: finished_items,
      regimen: regimen
      }
    {:ok, initial_state}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(:pause, state) do
    send(Farmbot.Scheduler, {:update,
        {:regimen, {self(), state.regimen, state.ran_items, state.start_time, :paused}}})
    {:noreply, %{state | flag: :paused, timer: tick(self())}}
  end

  def handle_cast(:resume, state) do
    send(Farmbot.Scheduler, {:update,
        {:regimen, {self(), state.regimen, state.ran_items, state.start_time, :normal}}})
    {:noreply, %{state | flag: :normal, timer: tick(self())}}
  end

  # if the regimen is paused
  def handle_info(:tick, %State{
      flag: :paused,
      timer: _,
      start_time: start_time,
      regimen_items: ri,
      ran_items: ran,
      regimen: regimen
    })
  do
    send(Farmbot.Scheduler, {:update, {:regimen, {self(), regimen, ran, start_time, :paused}}})
    {:noreply, %State{
        flag: :paused,
        timer: tick(self()),
        start_time: start_time,
        regimen_items: ri,
        ran_items: ran,
        regimen: regimen
      }}
  end

  # if there are no more items to run. exit this instance
  def handle_info(:tick, %State{
      flag: _,
      timer: _timer,
      start_time: _start_time,
      regimen_items: [],
      ran_items: _ran,
      regimen: regimen
    })
  do
    send(Farmbot.Scheduler, {:done, {:regimen, self(), regimen }})
    {:noreply, %State{regimen: regimen}}
  end

  def handle_info(:tick, %State{
      flag: :normal,
      timer: _timer,
      start_time: start_time,
      regimen_items: items,
      ran_items: ran_items,
      regimen: regimen
    })
  do
    now = Timex.now(Farmbot.BotState.get_config(:timezone))
    {items_to_do, remaining_items} =
      Enum.partition(items, fn(item) ->
        offset = item.time_offset
        run_time = Timex.shift(start_time, milliseconds: offset)
        should_run = Timex.after?(now, run_time)
        case ( should_run ) do
          true ->
            sequence = Farmbot.Sync.get_sequence(item.sequence_id)
            msg = "Time to run Sequence: " <> sequence.name
            Logger.debug(msg)
            # Log something here(msg, [:ticker, :success_toast], [regimen.name])
            Farmbot.Scheduler.add_sequence(sequence)
            Logger.debug("added sequence")
          false ->
            :ok
        end
        should_run
    end)
    if(items_to_do == []) do
      # Log something here("nothing to run this cycle", [], [regimen.name])
    end
    timer = tick(self())
    finished = ran_items ++ items_to_do
    # tell farmevent manager that these items are done.
    send(Farmbot.Scheduler, {:update, {:regimen, {self(), regimen, finished, start_time, :normal}}})
    {:noreply,
      %State{flag: :normal, timer: timer, start_time: start_time,
        regimen_items: remaining_items, ran_items: finished,
        regimen: regimen }}
  end

  def tick(pid) do
    Process.send_after(pid, :tick, @checkup_time)
  end

  @spec get_info(pid) :: State.t
  def get_info(pid) do
    GenServer.call(pid, :get_info)
  end

  @spec get_regimen_item_for_regimen(Regimen.t) :: RegimenItem.t
  def get_regimen_item_for_regimen(%Regimen{} = regimen) do
      Amnesia.transaction do
        selection = RegimenItem.where regimen_id == regimen.id
        selection |> Amnesia.Selection.values
      end
  end

  def terminate(:normal, state) do
    msg = "Regimen: #{state.regimen.name} completed without errors!"
    Logger.debug(msg)
    # Log something here(msg, [:ticker, :success_toast], ["RegimenManager"])
    # Farmbot.RPC.Handler.send_status
  end

  # this gets called if the scheduler crashes.
  # it is to stop orphaning of regimens
  def terminate(:e_stop, _state) do
    Logger.debug("cleaning up regimen")
  end

  def terminate(reason, state) do
    msg = "Regimen: #{state.regimen.name} completed with errors! #{inspect reason}"
    Logger.debug(msg)
    # Log something here(msg, [:error_toast], ["RegimenManager"])
  end
end
