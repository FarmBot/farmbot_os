defmodule RegimenVM  do
  @checkup_time 15000 #TODO: change this to 60 seconds
  require Logger

  @spec start_link(Regimen.t,list(RegimenItem.t), DateTime.t) :: {:ok, pid}
  def start_link(regimen, finished_items \\[], time) do
    GenServer.start_link(__MODULE__,{regimen, finished_items, time})
  end

  @spec init({Regimen.t, list(RegimenItem.t), DateTime.t}) :: {:ok, map}
  def init({regimen, finished_items, time}) do
    timer = Process.send_after(self(), :tick, @checkup_time)
    initial_state = %{
        running: true,
        timer: timer,
        start_time: time,
        regimen_items: get_regimen_item_for_regimen(regimen) -- finished_items,
        ran_items: finished_items,
        regimen: regimen
      }
    {:ok, initial_state}
  end

  # if there are no more items to run. exit this instance
  def handle_info(:tick, %{
      running: true,
      timer: _timer,
      start_time: _start_time,
      regimen_items: [],
      ran_items: _ran,
      regimen: regimen
    })
  do
    send(Farmbot.Scheduler, {:done, {:regimen, self(), regimen }})
    {:noreply, %{
        running: false,
        timer: nil,
        start_time: nil,
        regimen_items: [],
        ran_items: nil,
        regimen: regimen
      } }
  end

  def handle_info(:tick, %{
      running: true,
      timer: _timer,
      start_time: start_time,
      regimen_items: items,
      ran_items: ran_items,
      regimen: regimen
    })
  do
    now = Timex.now(BotState.get_config(:timezone))
    {items_to_do, remaining_items} =
      Enum.partition(items, fn(item) ->
        offset = item.time_offset
        run_time = Timex.shift(start_time, milliseconds: offset)
        should_run = Timex.after?(now, run_time)
        case ( should_run ) do
          true ->
            sequence = BotSync.get_sequence(item.sequence_id)
            msg = "Time to run Sequence: " <> sequence.name
            GenServer.call(Farmbot.Scheduler, {:add, {:sequence, sequence}})
            Logger.debug(msg)
            RPC.MessageHandler.log(msg, [:ticker, :success_toast], [regimen.name])
          false ->
            :ok
        end
        should_run
    end)
    if(items_to_do == []) do
      RPC.MessageHandler.log("nothing to run this cycle", [], [regimen.name])
    end
    timer = Process.send_after(self(), :tick, @checkup_time)
    finished = ran_items ++ items_to_do
    # tell farmevent manager that these items are done.
    send(Farmbot.Scheduler, {:done, {:regimen_items, {self(), regimen, finished, start_time}}})
    {:noreply,
      %{running: true, timer: timer, start_time: start_time,
        regimen_items: remaining_items, ran_items: finished,
        regimen: regimen }}
  end

  def get_regimen_item_for_regimen(regimen) do
    BotSync.get_regimen_items
    |> Enum.filter(fn(item) -> item.regimen_id == regimen.id end)
  end

  def terminate(:normal, state) do
    msg = "Regimen: #{state.regimen.name} completed without errors!"
    Logger.debug(msg)
    RPC.MessageHandler.log(msg, [:ticker, :success_toast], ["RegimenManager"])
    spawn fn -> RPC.MessageHandler.send_status end
  end

  def terminate(reason, state) do
    msg = "Regimen: #{state.regimen.name} completed with errors! #{inspect reason}"
    Logger.debug(msg)
    RPC.MessageHandler.log(msg, [:error_toast], ["RegimenManager"])
    spawn fn -> RPC.MessageHandler.send_status end
  end
end
