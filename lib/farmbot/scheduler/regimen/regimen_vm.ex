defmodule Farmbot.Scheduler.Regimen.VM  do
  @moduledoc """
    A state machine that tracks a regimen thru its lifecycle.
  """
  alias Farmbot.Sync
  alias Sync.Database.Regimen, as: Regimen
  alias Sync.Database.RegimenItem, as: RegimenItem
  alias Sync.Database.Sequence, as: Sequence
  alias Farmbot.BotState
  alias Farmbot.Scheduler
  use Amnesia
  use RegimenItem
  require Logger
  @checkup_time 15_000

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


  @spec start_link(Regimen.t,list(RegimenItem.t), DateTime.t)
    :: {:ok, pid} | {:error, {:already_started, pid}}
  def start_link(regimen, finished_items, time) do
    GenServer.start_link(__MODULE__, {regimen, finished_items, time})
  end

  @spec init({Regimen.t, list(RegimenItem.t), DateTime.t}) :: {:ok, map}
  def init({%Regimen{} = regimen, finished_items, time}) do
    items = get_regimen_item_for_regimen(regimen)
    first = List.first(items -- finished_items)
    first_time = Timex.shift(time, milliseconds: first.time_offset)

    Logger.debug "First item will execute on \
                  #{first_time.month}-#{first_time.day} \
                  at: #{first_time.hour}:#{first_time.minute}",
      channel: [:toast]


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
        {:regimen,
          {self(), state.regimen, state.ran_items, state.start_time, :paused}}})
    {:noreply, %{state | flag: :paused, timer: tick(self())}}
  end

  def handle_cast(:resume, state) do
    send(Farmbot.Scheduler, {:update,
        {:regimen, {self(),
          state.regimen, state.ran_items, state.start_time, :normal}}})
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
    send(Farmbot.Scheduler, {:update, {
      :regimen, {self(), regimen, ran, start_time, :paused}}})

    {:noreply, %State{
        flag: :paused,
        timer: tick(self()),
        start_time: start_time,
        regimen_items: ri,
        ran_items: ran,
        regimen: regimen}}
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
    send(Farmbot.Scheduler, {:done, {:regimen, self(), regimen}})
    {:noreply, %State{regimen: regimen}}
  end

  # this may or may not be a little too complex
  def handle_info(:tick, %State{
      flag: :normal,
      timer: _timer,
      start_time: start_time,
      regimen_items: items,
      ran_items: ran_items,
      regimen: regimen})
  do
    now = Timex.now(BotState.get_config(:timezone))
    {items_to_do, remaining_items} =
      Enum.partition(items, fn(item) ->
        offset = item.time_offset
        run_time = Timex.shift(start_time, milliseconds: offset)
        should_run = Timex.after?(now, run_time)
        if should_run do
          add_sequence(item.sequence_id)
        else
          :ok
        end
        should_run
    end)
    # if statement just for a log message ha
    if items_to_do == [] do
      Logger.debug ">> has nothing to run this cycle on: [#{regimen.name}]"
    end
    timer = tick(self())
    finished = ran_items ++ items_to_do
    # tell farmevent manager that these items are done.
    send(Farmbot.Scheduler, {:update,
      {:regimen, {self(), regimen, finished, start_time, :normal}}})
    {:noreply,
      %State{flag: :normal, timer: timer, start_time: start_time,
        regimen_items: remaining_items, ran_items: finished,
        regimen: regimen}}
  end

  def tick(pid) do
    Process.send_after(pid, :tick, @checkup_time)
  end

  @spec get_info(pid) :: State.t
  def get_info(pid) do
    GenServer.call(pid, :get_info)
  end

  @spec get_regimen_item_for_regimen(Regimen.t) :: RegimenItem.t
  @lint false # i dont want to alias Amnesia.Selection
  def get_regimen_item_for_regimen(%Regimen{} = regimen) do
      Amnesia.transaction do
        selection = RegimenItem.where regimen_id == regimen.id
        selection |> Amnesia.Selection.values
      end
  end

  def terminate(:normal, state) do
    Logger.debug ">> has completed regimen: \
                  #{state.regimen.name} without errors!",
    channel: [:toast], type: :success
  end

  # this gets called if the scheduler crashes.
  # it is to stop orphaning of regimens
  def terminate(:e_stop, _state) do
    Logger.debug ">> is cleaning up regimen"
  end

  def terminate(reason, state) do
    Logger.error ">> encountered errors completing \
                  a regimen! #{inspect reason} #{inspect state}"
  end

  # Tries to add a sequence too the Sequencer to be ran or queued.
  # If you give an integer it tries to look the sequence up in the dateabase
  # Then pipes it back thru itself.
  # if the piped function receives nil
  # it is assumed that either this sequence doesn't exist, or the bot is
  # out of sync. and tries to sync. This will be picked up upon next tick.
  # if we actually have a Sequence object, add the sequence to the stack.
  @spec add_sequence(integer | nil | Sequence.t) :: :ok
  defp add_sequence(id)
  when is_integer(id) do
    id |> Sync.get_sequence |> add_sequence
  end

  # this happens if the bot was not synced before this regimen started.
  defp add_sequence(nil) do
    Logger.error ">> could not find sequence.\
                  This may be a problem. I will try to sync to fix it."
    Sync.sync
  end

  defp add_sequence(%Sequence{} = sequence) do
    msg = ">> is going to run sequence: " <> sequence.name
    Logger.debug msg, channel: [:toast]
    Scheduler.add_sequence(sequence)
  end
end
