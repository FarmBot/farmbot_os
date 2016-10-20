defmodule RegimenVM  do
  @checkup_time 60000
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
        regimen_items: get_regimen_item_for_regimen(regimen)
      }
    {:ok, initial_state}
  end

  # if there are no more items to run. exit
  def handle_info(:tick, %{
      running: true,
      timer: _timer,
      start_time: _start_time,
      regimen_items: []
    })
  do
    GenServer.stop(self(), :no_items)
  end

  def handle_info(:tick, %{
      running: true,
      timer: _timer,
      start_time: start_time,
      regimen_items: items
    })
  do
    now = System.monotonic_time(:milliseconds)

    {items_to_do, remaining_items} =
      Enum.partition(items, fn(item) ->
        offset = Map.get(item, "time_offset")
        lhs = (now - start_time)
        rhs = (offset)
        if( lhs > rhs ) do
          runmsg = "Time to run a sequence at #{now}"
          RPCMessageHandler.log(runmsg)
          Logger.debug(runmsg)
          true
        else
          false
        end
    end)
    if(items_to_do == []) do
      nmsg = "Nothing to run this cycle"
      RPCMessageHandler.log(nmsg)
    end
    timer = Process.send_after(self(), :tick, @checkup_time)
    {:noreply, %{running: true, timer: timer, start_time: start_time, regimen_items: remaining_items }}
  end

  def get_regimen_item_for_regimen(regimen) do
    this_regimen_id = Map.get(regimen, "id")
    all_regimen_items = BotSync.get_regimen_items
    Enum.filter(all_regimen_items, fn(item) -> Map.get(item, "regimen_id") == this_regimen_id end)
  end

  def test do
    BotSync.sync
    item = %{"id" => 22, "regimen_id" => 4, "sequence_id" => 9, "time_offset" => 60000}
    GenServer.call(BotSync, {:add_regimen_item, item})
    regimen = BotSync.get_regimen(4)
    RegimenVM.start_link(regimen)
  end

end
