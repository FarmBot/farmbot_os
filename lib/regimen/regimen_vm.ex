defmodule RegimenVM  do
  @checkup_time 30000
  require Logger

  def start_link(regimen) do
    GenServer.start_link(__MODULE__,regimen)
  end

  def init(regimen) do
    timer = Process.send_after(self(), :tick, @checkup_time)
    now = System.monotonic_time(:milliseconds)
    initial_state = %{
        running: true,
        timer: timer,
        start_time: now,
        regimen_items: get_regimen_item_for_regimen(regimen),
        ran_items: [],
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
    {:noreply, nil
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
            RPCMessageHandler.log(msg)
          false ->
            RPCMessageHandler.log("Not running Sequence.")
        end
        ( lhs > rhs )
    end)
    timer = Process.send_after(self(), :tick, @checkup_time)
    {:noreply,
      %{running: true, timer: timer, start_time: start_time,
        regimen_items: remaining_items, ran_items: ran_items ++ items_to_do,
        regimen: regimen }}
  end

  def get_regimen_item_for_regimen(regimen) do
    this_regimen_id = Map.get(regimen, "id")
    all_regimen_items = BotSync.get_regimen_items
    Enum.filter(all_regimen_items, fn(item) -> Map.get(item, "regimen_id") == this_regimen_id end)
  end

  def terminate(:normal, state) do
    rname = Map.get(state.regimen, "name")
    msg = "Regimen: #{rname} completed without errors!"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, "success_toast")
  end

  def terminate(reason, state) do
    rname = Map.get(state.regimen, "name")
    msg = "Regimen: #{rname} completed with errors! #{inspect reason}"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, "error_toast")
  end


  def test do
    BotSync.sync
    item = %{"id" => 22, "regimen_id" => 4, "sequence_id" => 13, "time_offset" => 60000}
    GenServer.call(BotSync, {:add_regimen_item, item})
    regimen = BotSync.get_regimen(4)
    GenServer.call(FarmEventManager, {:add, {:regimen, regimen}})
  end

end
