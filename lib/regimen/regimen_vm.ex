defmodule RegimenVM  do
  @checkup_time 60000
  require Logger

  def start_link(regimen, finished_items \\[], time) do
    GenServer.start_link(__MODULE__,{regimen, finished_items, time})
  end

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

  # if there are no more items to run. exit
  def handle_info(:tick, %{
      running: true,
      timer: _timer,
      start_time: _start_time,
      regimen_items: [],
      ran_items: _ran,
      regimen: regimen
    })
  do
    send(FarmEventManager, {:done, {:regimen, {self(), regimen} }})
    {:noreply, nil }
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
    now = System.monotonic_time(:milliseconds)
    {items_to_do, remaining_items} =
      Enum.partition(items, fn(item) ->
        offset = Map.get(item, "time_offset")
        lhs = (now - start_time)
        rhs = (offset)
        case ( lhs > rhs ) do
          true ->
            sequence = BotSync.get_sequence(Map.get(item, "sequence_id"))
            msg = "Time to run Sequence: " <> Map.get(sequence, "name")
            GenServer.call(FarmEventManager, {:add, {:sequence, sequence}})
            Logger.debug(msg)
            RPCMessageHandler.log(msg, [:ticker, :success_toast], [Map.get(regimen, "name")])
          false ->
            :ok
        end
        ( lhs > rhs )
    end)
    if(items_to_do == []) do
      RPCMessageHandler.log("nothing to run this cycle", [], [Map.get(regimen, "name")])
    end
    timer = Process.send_after(self(), :tick, @checkup_time)
    finished = ran_items ++ items_to_do
    send(FarmEventManager, {:done, {:regimen_items, {self(), regimen, finished, start_time}}})
    {:noreply,
      %{running: true, timer: timer, start_time: start_time,
        regimen_items: remaining_items, ran_items: finished,
        regimen: regimen }}
  end

  def get_regimen_item_for_regimen(regimen) do
    this_regimen_id = Map.get(regimen, "id")
    BotSync.get_regimen_items
    |> Enum.filter(fn(item) -> Map.get(item, "regimen_id") == this_regimen_id end)
  end

  def terminate(:normal, state) do
    rname = Map.get(state.regimen, "name")
    msg = "Regimen: #{rname} completed without errors!"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, [:ticker, :success_toast], ["RegimenManager"])
  end

  def terminate(reason, state) do
    rname = Map.get(state.regimen, "name")
    msg = "Regimen: #{rname} completed with errors! #{inspect reason}"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, [:ticker, :error_toast], ["RegimenManager"])
  end


  def test do
    BotSync.sync
    item1 = %{"id" => 66, "regimen_id" => 8, "sequence_id" => 13, "time_offset" => 120000}
    item2 = %{"id" => 67, "regimen_id" => 8, "sequence_id" => 13, "time_offset" => 30000}
    GenServer.call(BotSync, {:add_regimen_item, item1})
    GenServer.call(BotSync, {:add_regimen_item, item2})
    regimen = BotSync.get_regimen(8)
    GenServer.call(FarmEventManager, {:add, {:regimen, regimen}})
  end

end
